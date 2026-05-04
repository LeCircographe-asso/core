# Modèles, concerns et zones de stabilité

> **Statut** : stable
> **Public cible** : contributeur
> **Dernière vérification** : 2026-05-01
> **Sources de vérité** : `app/models/`, `app/models/concerns/`, `db/schema.rb`, `spec/models/`.

> **Vocabulaire DDD-light** (voir [`../glossary.md`](../glossary.md))
>
> Les noms de classes Ruby utilisés ci-dessous sont systématiquement annotés `(cible : …)` quand ils correspondent à du code legacy en cours de migration :
>
> - `ContributionFormula` → `ContributionFormula`
> - `Contribution` → `Contribution`
>
> Plan de renommage : [`../migrations/vocabulary_migration.md`](../migrations/vocabulary_migration.md), `phase3-model-rename`.

Ce document remplace l'ancien trio `docs/MODEL_EVALUATION.md` + `docs/CONCERNS_ANALYSIS.md` + `docs/ZONES_CLASSIFICATION.md` qui s'étaient mis à diverger.

## 1. Architecture Person-based

```
Person (CRM, données personnelles)
  ├─> User (authentification — au plus un ; tout User a une Person)
  ├─> Membership (adhésion annuelle)
  ├─> Payment (transactions)
  ├─> Contribution (cible : Contribution — cotisation cirque)
  ├─> Attendance (présence quotidienne)
  └─> MemberNumberHistory (historique numéro membre)
```

Les formules de cotisation sont stockées dans `ContributionFormula` *(cible : `ContributionFormula`)*.

### Points forts confirmés

- Séparation claire **auth** (`User`) vs **profil** (`Person`).
- **Invariant** : `User` → `Person` obligatoire (`person_id` NOT NULL) ; `Person` peut exister sans `User`.
- One Source of Truth pour les données personnelles.
- Délégation propre `User → Person`.
- Côté `Person`, `has_one :user, dependent: :restrict_with_error` : pas de suppression incompatible tant qu’un compte web existe (archive / RGPD).
- `Payment` → `PaymentLine` polymorphique = un paiement peut regrouper adhésion + cotisation + don.
- Audit trail complet via `PaymentAuditLog` + UUID externe.
- Versioning sur `MembershipType` et `ContributionFormula` *(cible : `ContributionFormula`)* (`version`, `effective_from/until`, `change_reason`, `created_by_user_id`).

### Verdict d'audit (snapshot 2025-01-31)

| Dimension | Score | Commentaire |
| --- | --- | --- |
| Robustesse métier | 8 / 10 | Validations solides, quelques contradictions sur `Contribution` *(cible : `Contribution`)* |
| Performance | 6 / 10 | Indexes composites manquants (cf. §4) |
| Maintenabilité | 7 / 10 | Concerns bien organisés, dualité `expired?` à clarifier |
| Testabilité | 6 / 10 | Polymorphisme `PaymentLine` + `skip_overlap_validation` augmentent le coût des tests |

## 2. Concerns

Dix concerns en place :

- `Dateable` — formatage et scopes temporels.
- `Priceable` — conversion centimes / euros.
- `Statusable` — humanization et helpers de statuts.
- `Categorizable` — humanization des catégories.
- `Humanizable` — humanization d'enums divers.
- `Roleable` — gestion des rôles utilisateur.
- `Versionable` — versioning (`MembershipType`, `ContributionFormula` *(cible : `ContributionFormula`)*).
- `Validatable` — validations communes.
- `Duplicatable` — détection / fusion de doublons.
- `SoftDeletable` — soft delete avec `deleted_at`.

### Tableau d'inclusion

> Dans le tableau ci-dessous, `Contribution` cible `Contribution` et `ContributionFormula` cible `ContributionFormula` (cf. encadré en tête).

| Modèle | Statusable | Dateable | Priceable | Categorizable | Humanizable | Roleable | Versionable | SoftDeletable | EmailNormalizable |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Contribution | oui | oui | - | - | - | - | - | - | - |
| AttendanceList | oui | oui | - | - | - | - | - | - | - |
| AccountClaim | oui | oui | - | - | - | - | - | - | - |
| Person | - | oui | - | - | oui | - | - | oui | oui |
| NewsletterSubscriber | - | oui | - | - | - | - | - | - | oui |
| User | - | oui | - | - | - | oui | - | - | - |
| Payment | oui | oui | oui | - | oui | - | - | - | - |
| PaymentLine | - | - | oui | - | - | - | - | - | - |
| Event | - | oui | - | oui | - | - | - | - | - |
| Attendance | - | oui | - | - | - | - | - | - | - |
| ContributionFormula | - | - | oui | - | oui | - | oui | - | - |
| MembershipType | - | - | oui | oui | oui | - | oui | - | - |
| Membership | oui | oui | - | - | - | - | - | - | - |

### Règles de tenue

- Tout modèle avec `enum :status` doit inclure `Statusable`.
- Tout modèle avec colonnes datetime métier doit considérer `Dateable`.
- Le pattern soft-delete passe par `SoftDeletable` (et non plus des helpers ad-hoc).

## 3. Classification par zones

Cadre de **stabilité / risque** pour prioriser les tests. Pour les priorités actives en flux, se référer à [`../internal/todo.md`](../internal/todo.md).

- **Zone 1 (stable)** — comportement défini, tests immédiats requis.
- **Zone 2 (en cours)** — logique en évolution, tests après stabilisation.
- **Zone 3 (future ou hors-périmètre)** — pas de tests prioritaires.

### Modèles

#### Zone 1 — core business

`User`, `Person`, `Membership`, `Payment`, `PaymentLine`, `MembershipType`, `Contribution` *(cible : `Contribution`)* — tous testés, à compléter selon les gaps.

#### Zone 1 — business logic prioritaire

- `ContributionFormula` *(cible : `ContributionFormula`)* — pas de spec dédiée, **critique pour le pricing**, priorité haute.
- `Event` — partiel, ajouter edge cases.
- `AccountClaim` — workflow à couvrir.
- `Attendance` — logique quotidienne à couvrir.

#### Zone 1 — support

`MemberNumberHistory`, `PaymentAuditLog` — tests d'audit, priorité basse.

#### Zone 2

- `AttendanceList` — logique quotidienne à finaliser.
- `UserService` — usage incertain, à clarifier avant tests.

#### Zone 3

`Blog`, `Tag`, `TagBlog` (CMS basique), `PriceCatalog`, `PriceEntry` (tarification, non urgent), `EventAttendee` (legacy), `Session` (Rails system).

### Services

#### Zone 1 — testés

`MemberManagementService`, `People::PaymentCreator`, `People::MembershipUpgrader`. À maintenir.

#### Zone 1 — non testés à couvrir

`Admin::PaymentsService`, `People::NewsletterSignup`.

#### Zone 2 — fonctionnels mais à stabiliser

`Web::UserRegistration`, `People::Register`, `People::PaymentUpdater`, `People::PaymentCanceller`, `People::PaymentRestorer`, `People::AttachUserToPerson`, `People::AccountLinker`, `UserManagement::UserDeleter`, `People::AccountMerger`.

> Les classes `EventManagement::EventCreator/Updater/Deleter` existent dans `app/services/event_management/` mais sont **orphelines** : aucun contrôleur ne les appelle (CRUD inline dans `Admin::EventsController`). Cleanup tracé dans [`../internal/todo.md`](../internal/todo.md).

#### Zone 3

`People::PaymentRefund` (à concevoir), services dans `app/services/admin/operations/` (non utilisés, à auditer / nettoyer).

### Contrôleurs

Voir [`controllers.md`](controllers.md) pour le détail. Résumé :

- **Zone 1** — admin CRUD critiques (`Admin::Users`, `Admin::Memberships`, `Admin::Payments`, `Admin::Events`, `Admin::Dashboard`) et auth/checkout publics (`Sessions`, `Registrations`, `Checkout`).
- **Zone 2** — `AccountClaims`, `Passwords`, `Admin::ContributionFormulas`, `Admin::MemberNumbers`, autres admin CRUD standards.
- **Zone 3** — `Home`, `Pages`, `Events` public, `Blogs`, `Contacts`, `Admin::Blogs`, `Admin::Attendances`, `Admin::AttendanceLists`.

## 4. Dettes techniques identifiées

Liste héritée de `MODEL_EVALUATION.md` (snapshot 2025-01-31). À recroiser avec [`../internal/todo.md`](../internal/todo.md) avant action.

### 4.1 Dualité `expired?` (statut vs date)

`Membership#expired?` regarde `status`, `Contribution#expired?` regarde `expires_at`. Les scopes suivent la même asymétrie. Risque : tests déroutants, confusion développeurs.

Action ciblée :

```ruby
# Membership
def expired_by_date?
  Date.current > ended_at
end

def expired_status?
  status == "expired"
end
# Contribution : OK tel quel
```

### 4.2 `Contribution` *(cible : `Contribution`)* — validations contradictoires

`sessions_remaining` est forcé à `0` par défaut, validé `presence: true` si `has_session_limit?`, `presence: false` si Pack 10, et la validation custom contredit le default. Tests fragiles.

Action ciblée :

```ruby
# Migration
change_column_null :book_of_entries, :sessions_remaining, true
remove_column_default :book_of_entries, :sessions_remaining

# Validations
validates :sessions_remaining, presence: true,
                               numericality: { greater_than: 0 },
                               if: :has_session_limit?
validates :sessions_remaining, absence: true,
                               if: -> { subscription_plan&.duration.in?(["trimester", "annual"]) }
```

### 4.3 `Membership#upgrade_to!` — `skip_overlap_validation` partout

`upgrade_to!` crée la nouvelle `Membership` sans désactiver l'ancienne immédiatement, ce qui forcerait une `no_overlapping_active_memberships`. Le contournement actuel est `skip_overlap_validation` répandu dans le code.

Action ciblée : inactiver l'ancienne dans la même transaction, puis créer la nouvelle, puis retirer `skip_overlap_validation`.

### 4.4 Indexes manquants

```ruby
add_index :payments, [:status, :created_at], name: "idx_payments_status_created"
add_index :memberships, [:membership_type_id, :status], name: "idx_memberships_type_status"
add_index :payment_lines, :amount_cents, name: "idx_payment_lines_amount"
add_index :book_of_entries, [:person_id, :status, :expires_at], name: "idx_boe_person_status_exp"
add_index :subscription_plans, [:membership_type_id, :duration], name: "idx_sub_plans_type_duration"
```

Impact attendu : dashboards admin plus rapides, scalabilité accrue.

### 4.5 `Contribution.expires_at` *(cible : `Contribution.expires_at`)* nullable mais NOT NULL en migration

Pack 10 force `expires_at` à `Time.current + 100.years` faute d'accepter `NULL`. Conséquence : queries `WHERE expires_at < ?` partout, factories complexes.

Action ciblée : autoriser `NULL` pour Pack 10 ou table séparée pour les packs « illimités ». À discuter en équipe.

### 4.6 `PaymentLine` — polymorphisme sans foreign key

Trade-off accepté (flexibilité > intégrité référentielle) mais à garder en tête lors des migrations. Voir [`../payments.md`](../payments.md) pour la dette `item_type:"Payment"` sur les dons.

### 4.7 Newsletter `newsletter_subscribed` toujours sur `Person`

Legacy non supprimé. Le module Newsletter a son propre modèle `NewsletterSubscriber`. Action : retirer l'attribut sur `Person` ou clarifier son rôle (drapeau de consentement, par ex.).

## 5. Documentation liée

- [`overview.md`](overview.md) — architecture générale Person/User, RGPD, ViewComponents.
- [`services.md`](services.md) — catalogue des services `People::*`.
- [`controllers.md`](controllers.md) — état des contrôleurs.
- [`../domain/business_logic.md`](../domain/business_logic.md) — règles métier.
- [`../development/testing.md`](../development/testing.md) — guide tests.
