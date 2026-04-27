# Migration de Vocabulaire — DDD-light

> Plan progressif d'alignement vocabulaire / code / documentation, sans big-bang. Chaque phase est livrable seule, sans casser la précédente.

**Dernière mise à jour :** 2026-04-27
**Vocabulaire cible :** voir [../glossary.md](../glossary.md).

---

## 1. Mapping ancien → nouveau

### 1.1 Modèles et tables

| Ancien (legacy) | Nouveau (cible) | Type | Phase |
| --- | --- | --- | --- |
| `SubscriptionPlan` (modèle) | `ContributionFormula` | rename modèle + table | `phase3-model-rename` |
| `subscription_plans` (table) | `contribution_formulas` | rename DB | `phase3-model-rename` |
| `BookOfEntry` (modèle) | `Contribution` | rename modèle + table | `phase3-model-rename` |
| `book_of_entries` (table) | `contributions` | rename DB | `phase3-model-rename` |
| `UserMembership` (modèle) | (supprimé) | supprimé (architecture Person) | déjà archivé |
| `EventAttendee` (modèle legacy) | (supprimé après audit) | suppression conditionnelle | `phase4-legacy-cleanup` |

### 1.2 Colonnes et associations

| Ancien | Nouveau | Localisation | Phase |
| --- | --- | --- | --- |
| `book_of_entry_id` (sur `attendances`) | `contribution_id` | DB + code | `phase3-model-rename` |
| `subscription_plan_id` (sur ex-`book_of_entries`) | `contribution_formula_id` | DB + code | `phase3-model-rename` |
| `payment_lines.item_type = "SubscriptionPlan"` | `"ContributionFormula"` | data migration | `phase3-model-rename` |
| `payment_lines.item_type = "BookOfEntry"` | `"Contribution"` | data migration | `phase3-model-rename` |
| `payment_lines.item_type = "Payment"` (don) | `"Donation"` | data migration | `phase1-donation-fix` |
| `payments.donation` (cents) | (supprimé) | DB + code | `phase1-donation-fix` |

### 1.3 Méthodes et concepts

| Ancien | Nouveau | Localisation | Phase |
| --- | --- | --- | --- |
| `Person#create_subscription!` | `Person#create_contribution!` | `app/models/person.rb` | `phase0-quick-wins` (alias) puis `phase3` |
| `Person#upgrade_subscription!` | `Person#upgrade_contribution!` | `app/models/person.rb` | `phase0-quick-wins` (alias) puis `phase3` |
| `Person#active_subscription?` | `Person#active_contribution?` | `app/models/person.rb` | `phase0-quick-wins` |
| `Person#current_subscription` | `Person#current_contribution` | `app/models/person.rb` | `phase0-quick-wins` |
| `Person#subscriptions` | `Person#contributions` | `app/models/person.rb` | `phase0-quick-wins` (alias) |
| `User#inferior_rights` | `User#subordinate_roles` | `app/models/user.rb` | `phase0-quick-wins` |
| `bookOfEntryValidation` (callback) | (supprimé — déjà fait) | `app/models/book_of_entry.rb` | déjà fait |
| `People::SubscriptionCreator` | `People::ContributionCreator` | `app/services/people/` | `phase3-model-rename` |
| `People::SubscriptionUpgrader` | `People::ContributionUpgrader` | `app/services/people/` | `phase3-model-rename` |
| `People::SubscriptionStatusEnsurer` | `People::ContributionStatusEnsurer` | `app/services/people/` | `phase3-model-rename` |
| `SubscriptionStatusBadgeComponent` | `ContributionStatusBadgeComponent` | `app/components/` | `phase2-component-rename` |

### 1.4 Vocabulaire documentaire

| Ancien | Nouveau | Localisation |
| --- | --- | --- |
| « abonnement » | « cotisation » | doc et UI |
| « plan d'abonnement » | « formule de cotisation » | doc, seeds, UI |
| « subscription » (cirque) | « contribution » | doc, code, comments |
| « subscription » (newsletter) | (conservé) | newsletter uniquement |
| « article d'adhésion » / « article de cotisation » | « type d'adhésion » / « formule de cotisation » | seeds, doc |
| « carnet d'entrées » (sauf Pack 10) | « cotisation » | doc, code |

---

## 2. Phases (ordre canonique)

### Phase 0 — Quick wins (zéro impact DB)
- Renommer `User#inferior_rights` → `User#subordinate_roles` (alias rétro-compat avec `ActiveSupport::Deprecation.warn`).
- Renommer `Person#active_subscription?` → `Person#active_contribution?` (idem).
- Renommer `Person#current_subscription` → `Person#current_contribution` (idem).
- Ajouter alias `Person#contributions` ↔ `Person#subscriptions`.
- Supprimer logs de debug oubliés (`Rails.logger.debug` orphelins, `puts`).
- ✅ **Tests à mettre à jour** : remplacer les usages existants.

### Phase 1 — Donations propres
- `People::PaymentCreator` : retirer la réécriture `item_type: "Donation" → "Payment"` (L92 de `app/services/people/payment_creator.rb`).
- Data migration : `PaymentLine.where(item_type: "Payment").where("description ILIKE '%don%' OR description = 'Donation'").update_all(item_type: "Donation")`.
- Backfill : pour chaque `Payment.where("donation > 0")`, créer une `PaymentLine` `item_type: "Donation"` si absente.
- Migration DB : `remove_column :payments, :donation`.
- Simplifier `Payment#with_donations`, `Admin::PaymentsService` (filtrage propre `item_type = "Donation"`).
- Ajouter `validates :item_type, inclusion: { in: %w[Membership MembershipType ContributionFormula Contribution Donation SubscriptionPlan BookOfEntry] }` sur `PaymentLine` (les valeurs legacy seront retirées en phase 3).
- Mettre à jour `spec/factories/payments.rb` (trait `:with_donation`).

### Phase 2 — Composant cosmétique
- Renommer `SubscriptionStatusBadgeComponent` → `ContributionStatusBadgeComponent`.
- Mettre à jour les 7 vues qui le référencent.
- Pas d'impact DB ni service.

### Phase 3 — Renommage modèles + DB
- **Pré-requis** : phases 0 + 1 + 2 mergées et stables en staging.
- DB :
  - `rename_table :subscription_plans, :contribution_formulas`.
  - `rename_table :book_of_entries, :contributions`.
  - `rename_column :attendances, :book_of_entry_id, :contribution_id`.
  - `rename_column :contributions, :subscription_plan_id, :contribution_formula_id`.
  - Data migration : `payment_lines.item_type` (`SubscriptionPlan → ContributionFormula`, `BookOfEntry → Contribution`).
- Code :
  - Renommer modèles `SubscriptionPlan` → `ContributionFormula`, `BookOfEntry` → `Contribution`.
  - Renommer fichiers (snake_case Zeitwerk).
  - Renommer services `People::Subscription*` → `People::Contribution*`.
  - Renommer méthodes `Person#*subscription*` → `Person#*contribution*` (suppression des alias rétro-compat ajoutés en phase 0).
- Mettre à jour validation `PaymentLine` pour ne plus accepter `SubscriptionPlan` / `BookOfEntry`.
- Mettre à jour TOUTES les vues, helpers, factories, specs, locales.

### Phase 4 — Cleanup legacy
- Auditer puis supprimer `EventAttendee` si la fonctionnalité est intégrée à `Attendance`.
- Extraire la logique métier de `Person` (>500 lignes) vers des services dédiés.
- Supprimer définitivement les alias rétro-compat ajoutés en phase 0.
- Supprimer le champ `donation` de `payments` (si pas déjà fait phase 1).

---

## 3. Statut documentaire (par phase)

| Phase | Code | Doc principale | Glossaire |
| --- | --- | --- | --- |
| Phase 0 | en cours | mentionne « code actuel : `inferior_rights` (alias `subordinate_roles`) » | utilise `subordinate_roles` |
| Phase 1 | en cours | mentionne « actuel : `item_type: "Payment"` pour les dons (legacy à retirer) » | utilise `Donation` |
| Phase 2 | à faire | mentionne `ContributionStatusBadgeComponent` (legacy : `SubscriptionStatusBadgeComponent`) | idem |
| Phase 3 | à faire | mentionne `Contribution` (code actuel : `BookOfEntry`) jusqu'au merge | idem |
| Phase 4 | à faire | toute mention legacy est supprimée | idem |

> **Convention documentaire** : tant que le code n'est pas migré, les documents utilisent la forme :
> > « Vocabulaire cible : `Contribution` (code actuel : `BookOfEntry`) ».
> > Quand la phase 3 est fusionnée, cette mention disparaît.

---

## 4. Changements documentaires immédiats (cette PR)

### 4.1 Safe cleanup
- Création des nouvelles documents : `glossary.md`, `domain_model.md`, `payments.md`, `migrations/vocabulary_migration.md`.
- Réécriture du `README.md` (court, lien glossaire, versions à jour).
- Réécriture de `db/seeds.rb`, `db/seeds/subscription_plans.rb`, `db/seeds/membership_types.rb` (logs et bandeaux français).
- Réécriture des sections 4 et 5 de `docs/domain/business_logic.md`.
- MAJ de `docs/architecture/services.md`.
- Alignement de `MODEL_EVALUATION`, `CONCERNS_ANALYSIS`, `ZONES_CLASSIFICATION`, `UX_GUIDE`, `TODO`, `ARCHITECTURE_GUIDE`.

### 4.2 Corrections à faire avec les migrations futures
- Renommage `SubscriptionPlan → ContributionFormula` dans seeds, factories, vues, locales : **lié à la phase 3**.
- Renommage `BookOfEntry → Contribution` : **lié à la phase 3**.
- Suppression `payments.donation` colonne : **lié à la phase 1**.

### 4.3 Documentation legacy temporaire
- `docs/rake_archive/*.rake` reçoit un encadré « LEGACY ARCHIVE » expliquant le statut.
- `docs/legacy/` (ex `docs/knowledge/`) reçoit son propre `README.md` expliquant que l'ensemble est un « Journal historique non normatif » à différencier des sources canoniques.

### 4.4 Vérifications manuelles
- Liens cassés dans 8 modèles vers `domain_model_circographe.md` (inexistant) → remplacés par `docs/domain_model.md`.
- Lien cassé dans `README.md` vers `CONTRIBUTING.md` (inexistant) → soit créer le fichier, soit supprimer la mention. Décision dans cette PR : supprimer le lien (pas de standard CONTRIBUTING aujourd'hui).
- Lien cassé `CHANGELOG.md` (inexistant) → idem, supprimer la mention dans le README.

---

## 5. Outillage de garde-fou (à ajouter)

### 5.1 Règle de nommage
Un fichier `.cursor/rules/naming-rules.md` (ou section dans `AGENTS.md`) explicite les règles :
- Modèles, services, composants : noms anglais alignés sur le glossaire.
- Méthodes / colonnes : `snake_case` du nom anglais cible.
- Termes interdits : voir glossary §1.7.

### 5.2 Specs garde-fou (à ajouter en phase 1)
```ruby
# spec/models/payment_line_spec.rb
it "n'accepte pas item_type = 'Payment'" do
  expect { build(:payment_line, item_type: "Payment").save!(validate: true) }
    .to raise_error(ActiveRecord::RecordInvalid)
end
```

---

## 6. Documents liés

- [../glossary.md](../glossary.md) — vocabulaire canonique.
- [../domain_model.md](../domain_model.md) — modèle de domaine.
- [../payments.md](../payments.md) — paiements et dons.
- [../domain/business_logic.md](../domain/business_logic.md) — règles métier.
- [../architecture/services.md](../architecture/services.md) — services.
