# Paiements, lignes et dons — Le Circographe

> **Statut** : stable
> **Public cible** : contributeur
> **Dernière vérification** : 2026-05-01
> **Sources de vérité** : `app/models/payment.rb`, `app/models/payment_line.rb`, `app/services/people/payment_recorder.rb`, `app/services/people/payment_creator.rb`.

> Vocabulaire utilisé : voir [glossary.md](glossary.md).

---

## 1. Modèle synthétique

```
Payment (transaction)
├── PaymentLine (item polymorphique)  ── item_type ──> Membership
├── PaymentLine                        ── item_type ──> ContributionFormula
├── PaymentLine                        ── item_type ──> Contribution
├── PaymentLine                        ── item_type ──> MembershipType
└── PaymentLine                        ── item_type ──> Donation
```

**Invariant fondamental** : `payment.payment_lines.sum(:amount_cents) == payment.total_cents`.

---

## 2. `Payment`

- `belongs_to :person` — qui paie.
- `belongs_to :recorded_by, class_name: "User"` — qui enregistre.
- Champs principaux : `total_cents`, `status`, `payment_method`, `uuid`, `notes`, `offer_reason`.
- Statuts : `:pending → :success | :cancel`.
- Méthodes de paiement : `:cash`, `:card`, `:cheque`, `:transfer`, `:offered`.
- `offer_reason` est persisté sur `payments` et requis si `payment_method == "offered"`.

### 2.1 Anonymisation RGPD

```ruby
Payment#anonymize!
# - cible : détacher l'identité tout en gardant une trace comptable
# - garde un hash de traçabilité pour la comptabilité
# - à vérifier : le schéma courant impose payments.person_id NOT NULL
```

---

## 3. `PaymentLine`

- `belongs_to :payment`.
- `belongs_to :item, polymorphic: true` (`item_type` + `item_id`).
- Champs : `amount_cents`, `description`.

### 3.1 Valeurs canoniques de `item_type`

| Cas | `item_type` cible | `item_id` | Notes |
| --- | --- | --- | --- |
| Adhésion créée par ce paiement | `"Membership"` | `membership.id` | adhésion fraîchement créée |
| Renouvellement / catalogue | `"MembershipType"` | `membership_type.id` | rare, surtout pour audit |
| Achat de cotisation | `"ContributionFormula"` | `formula.id` | catalogue |
| Cotisation existante (réf.) | `"Contribution"` | `contribution.id` | instance achetée |
| Don | `"Donation"` | `payment.id` | création actuelle ; données anciennes à vérifier |

### 3.2 Création multi-lignes

```ruby
People::PaymentRecorder.new(
  person: person,
  recorded_by: current_user,
  total_cents: 1700,
  payment_method: "cash",
  payment_lines: [
    { item_type: "MembershipType",      item_id: 1, amount_cents: 700,  description: "Adhésion Cirque Réduit" },
    { item_type: "ContributionFormula", item_id: 4, amount_cents: 1000, description: "Cotisation Pack 10" }
  ]
).call
```

> `People::PaymentRecorder` est le service canonique. `People::PaymentCreator` reste une façade compatible.

---

## 4. Donations — état actuel et cible

### 4.1 Cible

Une donation est une `PaymentLine` :

```ruby
PaymentLine.new(
  payment: payment,
  item_type: "Donation",
  item_id:   payment.id,         # ou un id technique stable (à figer en phase 1)
  amount_cents: 500,
  description: "Don libre"
)
```

**Aucune `PaymentLine` ne doit avoir `item_type: "Payment"`**.

### 4.2 État actuel — code vs données legacy

**Code (`People::PaymentRecorder`)** : les lignes de don utilisent `item_type: "Donation"` et `item_id = payment.id`. `PaymentLine` valide désormais les `item_type` autorisés.

```ruby
# app/services/people/payment_recorder.rb (extrait)
payment.payment_lines.create!(
  item_type: line[:item_type],
  item_id: donation_line?(line[:item_type]) ? payment.id : line[:item_id],
  ...
)
```

**Données** : la migration `20260427084000_backfill_donation_item_type_on_payment_lines.rb` couvre le backfill historique. Vérifier en base de production qu'aucune ligne `item_type: "Payment"` ne subsiste.

### 4.3 Nettoyage restant

- Ajout d'un rapport d'intégrité paiement/lignes.
- Vérifier l'affichage uniforme de `offer_reason` dans tous les écrans admin de paiement.

---

## 5. Audit et observabilité

### 5.1 `PaymentAuditLog`

Trace toute opération sur `Payment` :
- création (`People::PaymentRecorder`)
- annulation / soft-delete (`People::PaymentCanceller`)
- restauration (`People::PaymentRestorer`)
- anonymisation (`Payment#anonymize!`)

### 5.2 Instrumentation `ActiveSupport::Notifications`

- `payment.created` — création réussie d'un paiement.
- `payment.cancelled` — paiement annulé.
- `payment.anonymized` — anonymisation effectuée.

---

## 6. Règles d'intégrité (à garantir)

| Règle | Statut | Tracé dans |
| --- | --- | --- |
| Somme `payment_lines` == `payment.total_cents` | ✅ vérifié dans `People::PaymentRecorder` | service |
| `payment_method == :offered` ⇒ raison présente | ✅ vérifié et persisté | `People::OfferPolicy`, `Payment`, `People::PaymentRecorder` |
| Anonymisation paiement compatible DB | ✅ aligné | `Payment#anonymize!` garde `person_id`, stocke `original_person_identifier`, marque `anonymized_at` |
| Aucune `PaymentLine.item_type == "Payment"` | À vérifier en données | todo |
| Inclusion stricte des `item_type` autorisés | ✅ validation modèle | `PaymentLine::ALLOWED_ITEM_TYPES` |

---

## 7. Documents liés

- [glossary.md](glossary.md) — vocabulaire canonique.
- [domain_model.md](domain_model.md) — modèle de domaine et cycles de vie.
- [migrations/vocabulary_migration.md](migrations/vocabulary_migration.md) — plan de migration.
- [domain/business_logic.md](domain/business_logic.md) — règles métier détaillées.
- [architecture/services.md](architecture/services.md) — services orchestrateurs.
