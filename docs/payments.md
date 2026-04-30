# Paiements, lignes et dons — Le Circographe

> **Statut** : stable
> **Public cible** : contributeur
> **Dernière vérification** : 2026-05-01
> **Sources de vérité** : `app/models/payment.rb`, `app/models/payment_line.rb`, `app/services/people/payment_creator.rb`.

> Vocabulaire utilisé : voir [glossary.md](glossary.md).

---

## 1. Modèle synthétique

```
Payment (transaction)
├── PaymentLine (item polymorphique)  ── item_type ──> Membership
├── PaymentLine                        ── item_type ──> ContributionFormula  (legacy: SubscriptionPlan)
├── PaymentLine                        ── item_type ──> Contribution         (legacy: BookOfEntry, rare)
├── PaymentLine                        ── item_type ──> MembershipType
└── PaymentLine                        ── item_type ──> Donation             (création actuelle via `PaymentCreator` ; données anciennes peuvent encore avoir `Payment`, voir §4)
```

**Invariant fondamental** : `payment.payment_lines.sum(:amount_cents) == payment.total_cents`.

---

## 2. `Payment`

- `belongs_to :person` — qui paie.
- `belongs_to :recorded_by, class_name: "User"` — qui enregistre.
- Champs principaux : `total_cents`, `status`, `payment_method`, `offer_reason`, `uuid`, `donation` (champ historique à éliminer — voir §4.4).
- Statuts : `:pending → :success | :cancel`.
- Méthodes de paiement : `:cash`, `:card`, `:cheque`, `:transfer`, `:offered`.
- **Règle** : `payment_method == :offered` impose un `offer_reason`.

### 2.1 Anonymisation RGPD

```ruby
Payment#anonymize!
# - person_id → NULL
# - garde un hash de traçabilité pour la comptabilité
# - utilisé par People::AccountAnonymizer (cible)
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
| Achat de cotisation | `"ContributionFormula"` | `formula.id` | legacy : `"SubscriptionPlan"` |
| Cotisation existante (réf.) | `"Contribution"` | `contribution.id` | legacy : `"BookOfEntry"` (rare) |
| Don | `"Donation"` | `payment.id` (provisoire) | création : service ci-dessous ; legacy DB : encore `"Payment"` jusqu’à backfill complet — voir §4 |

### 3.2 Création multi-lignes

```ruby
People::PaymentCreator.new(
  person: person,
  recorded_by_id: current_user.id,
  total_cents: 1700,
  payment_method: "cash",
  payment_lines: [
    { item_type: "MembershipType",      item_id: 1, amount_cents: 700,  description: "Adhésion Cirque Réduit" },
    { item_type: "ContributionFormula", item_id: 4, amount_cents: 1000, description: "Cotisation Pack 10" }
  ]
).call
```

> Le service vérifie que la somme des lignes = `total_cents`. Sinon, `failure`.

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

**Code (`People::PaymentCreator`)** : la ligne simple utilise `item_type` défaut `"Donation"` et **conserve** ce type pour les dons (`donation_line?` → `item_id` = `payment.id`). Il n’y a plus de réécriture systématique vers `"Payment"` dans ce chemin.

```ruby
# app/services/people/payment_creator.rb (extrait)
payment.payment_lines.create!(
  item_type: line_item_type, # ex. "Donation"
  item_id: donation_line?(line_item_type) ? payment.id : item_id,
  ...
)
```

**Données** : des lignes historiques peuvent encore avoir `item_type: "Payment"` jusqu’à application complète des migrations de backfill (`db/migrate/*backfill_donation*`). Les requêtes métier doivent couvrir **Donation** comme canon et **Payment** comme legacy le temps du nettoyage (voir `phase1-donation-fix`).

### 4.3 Plan de migration (phase `phase1-donation-fix`)

1. **Backfill** : data migration mettant à jour les lignes existantes
   ```ruby
   PaymentLine.where(item_type: "Payment")
              .where("description ILIKE ? OR description = ?", "%don%", "Donation")
              .update_all(item_type: "Donation")
   ```
2. **Nettoyage code résiduel** : retirer toute référence encore basée sur `item_type: "Payment"` pour les dons dans les modèles/helpers commentés ; aligner les specs/factories sur `"Donation"` uniquement.
3. **Mise à jour des requêtes** : simplifier `Payment#with_donations` et `Admin::PaymentsService` à `where(payment_lines: { item_type: "Donation" })`.
4. **Specs à ajuster** : `spec/factories/payments.rb` trait `:with_donation` doit créer une `PaymentLine` `item_type: "Donation"`.
5. **Validation modèle** : ajouter `validates :item_type, inclusion: { in: %w[Membership MembershipType ContributionFormula Contribution Donation] }` sur `PaymentLine`.

### 4.4 Champ `Payment#donation` (historique)

Le champ `donation` sur la table `payments` est un vestige : il duplique l'information stockée dans une ligne. À éliminer dans la même phase :

- Backfill : pour chaque `payment` avec `donation > 0`, vérifier qu'une `PaymentLine` `item_type: "Donation"` existe ; sinon, en créer une.
- Migration : `remove_column :payments, :donation`.
- Code : retirer toutes les références (services, vues, helpers, factories).

---

## 5. Audit et observabilité

### 5.1 `PaymentAuditLog`

Trace toute opération sur `Payment` :
- création (`People::PaymentCreator`)
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
| Somme `payment_lines` == `payment.total_cents` | ✅ vérifié dans `People::PaymentCreator` | service |
| `payment_method == :offered` ⇒ `offer_reason` présent | ✅ vérifié | UI + service |
| Pas de paiement orphelin (`person_id` ou hash post-anonymisation) | ✅ | `Payment#anonymize!` |
| Aucune `PaymentLine.item_type == "Payment"` | ❌ legacy actif | `phase1-donation-fix` |
| Inclusion stricte des `item_type` autorisés | ❌ pas de validation | `phase1-donation-fix` |

---

## 7. Documents liés

- [glossary.md](glossary.md) — vocabulaire canonique.
- [domain_model.md](domain_model.md) — modèle de domaine et cycles de vie.
- [migrations/vocabulary_migration.md](migrations/vocabulary_migration.md) — plan de migration.
- [domain/business_logic.md](domain/business_logic.md) — règles métier détaillées.
- [architecture/services.md](architecture/services.md) — services orchestrateurs.
