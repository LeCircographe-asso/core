# Règles d'intégrité des données

> **Statut** : stable
> **Public cible** : contributeur
> **Dernière vérification** : 2026-05-01
> **Sources de vérité** : `app/models/`, `db/schema.rb`, `app/services/people/`.

Checklist des invariants qui ne doivent jamais être violés. Chaque règle indique la garde technique qui l'impose.

---

## 1. Identité (Person / User)

| Règle | Garde |
|-------|-------|
| Tout `User` a une `Person` | `belongs_to :person` NOT NULL en DB ; callback `ensure_person_for_new_record` sur `User` |
| Une `Person` peut exister sans `User` | Légal — fiche CRM sans compte web |
| Un `User` ne peut pas être lié à deux `Person` | `user_id` est unique sur la table `people` |
| Une `Person` ne peut pas avoir deux `User` | `has_one :user, dependent: :restrict_with_error` |
| L'email `Person.email` et `User.email_address` ne peuvent pas être en collision cross-table | `Identity::EmailPolicy` valide lors de la création/mise à jour |
| Suppression `Person` interdite si données financières | `Person#has_financial_data?` bloque l'archivage sauf `super_admin` |

---

## 2. Adhésions (Membership)

| Règle | Garde |
|-------|-------|
| Une `Person` ne peut pas avoir deux adhésions actives qui se chevauchent | Validation `no_overlapping_active_memberships` (skip si `skip_overlap_validation`) |
| `ended_at > started_at` | Validation modèle `Membership` |
| Upgrade Circus → Basic interdit | `Membership#can_upgrade_to?` retourne `false` |
| Upgrade même type interdit | `Membership#can_upgrade_to?` retourne `false` |
| Création adhésion → génère toujours un `Payment` | `Person#create_membership!` en transaction |

---

## 3. Cotisations (Contribution)

| Règle | Garde |
|-------|-------|
| Achat cotisation requiert une `Membership` Cirque active | `Person#can_buy_contribution_formulas?` vérifié dans `ContributionFormulasController#new` |
| Pack 10 : `sessions_remaining` initialisé à `sessions_count`, jamais nil pour un plan à séances | `ContributionFormula#sessions_count` par défaut 10 |
| Plans illimités (Trimestre, Annuel, Day) : `sessions_remaining` doit être `nil` | Invariant à vérifier — pas encore de validation DB, voir todo §4 |
| `Contribution#use_session!` refuse si `sessions_remaining == 0` | `can_use?` vérifié avant `use_session!` |
| Upgrade Day → autre : interdit | `upgrade_contribution!` bloque ce cas |

---

## 4. Paiements (Payment)

| Règle | Garde |
|-------|-------|
| `recorded_by_id` toujours présent | Validation présence dans tous les services `People::Payment*` |
| Montants toujours en centimes en DB (`price_cents`, `total_cents`) | Convention uniforme — jamais de flottants |
| Somme des `PaymentLine.amount_cents` = `Payment.total_cents` | `People::PaymentCreator` vérifie la cohérence avant sauvegarde |
| Don : `PaymentLine.item_type` = `"Donation"` (pas `"Payment"`) | `PaymentCreator` force le bon `item_type` sur les lignes de don |
| Suppression paiement → soft-delete uniquement | `Payment#cancel!` (pas de hard delete) |
| `offer_reason` requis si `payment_method == "offered"` | Validation `requires_offer_reason` dans `People::PaymentCreator` |

---

## 5. Présences (Attendance)

| Règle | Garde |
|-------|-------|
| Unicité `person_id + event_id` pour les présences événements | Validation `uniqueness` sur `Attendance` |
| Unicité `person_id + date` pour les présences libres (sans event_id) | Validation conditionnelle sur `Attendance` |
| `use_session!` uniquement si `can_use?` retourne `true` | `AttendanceManagement::CheckInService` vérifie avant de créer |
| Suppression présence → recrédite le carnet si applicable | `AttendanceManagement::AttendanceRemover#refund_session!` |

---

## 6. Requêtes d'intégrité à surveiller

Ces requêtes permettent de détecter des états invalides en base :

```ruby
# Users sans Person (ne doit jamais exister après migration)
User.where(person_id: nil)

# Persons avec plusieurs Users actifs (impossible si contrainte respectée)
Person.joins(:user).group("people.id").having("count(users.id) > 1")

# Cotisations pack10 avec sessions_remaining nil (invalide)
Contribution.pack10.where(sessions_remaining: nil)

# Cotisations illimitées avec sessions_remaining non-nil (invalide)
Contribution.where.not(contribution_formula: ContributionFormula.pack10).where.not(sessions_remaining: nil)

# Paiements sans payment_lines (invalide si total_cents > 0)
Payment.left_joins(:payment_lines).where(payment_lines: { id: nil }).where("total_cents > 0")

# PaymentLines dont la somme ne correspond pas au Payment total
Payment.joins(:payment_lines)
       .group("payments.id, payments.total_cents")
       .having("SUM(payment_lines.amount_cents) != payments.total_cents")
```

> Ces requêtes sont candidates pour une tâche Rake de rapport d'intégrité (voir [`../internal/todo.md`](../internal/todo.md) §7).
