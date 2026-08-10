# Modèles, concerns et zones de stabilité

> **Statut** : stable
> **Public cible** : contributeur
> **Dernière vérification** : 2026-08-10
> **Sources de vérité** : `app/models/`, `app/models/concerns/`, `db/schema.rb`, `spec/models/`.

> **Vocabulaire DDD-light** (voir [`../glossary.md`](../glossary.md)) : `Contribution` / `ContributionFormula` sont les noms de code actuels — le renommage `phase3-model-rename` du [plan de migration](../migrations/vocabulary_migration.md) est terminé, plus d'annotation `(cible : …)` nécessaire.

Ce document remplace l'ancien trio `docs/MODEL_EVALUATION.md` + `docs/CONCERNS_ANALYSIS.md` + `docs/ZONES_CLASSIFICATION.md` qui s'étaient mis à diverger.

## 1. Architecture Person-based

```
Person (CRM, données personnelles)
  ├─> User (authentification — au plus un ; tout User a une Person)
  ├─> Membership (adhésion annuelle)
  ├─> Payment (transactions)
  ├─> Contribution (cotisation cirque)
  ├─> Attendance (présence quotidienne)
  └─> MemberNumberHistory (historique numéro membre)
```

Les formules de cotisation sont stockées dans `ContributionFormula`.

### Points forts confirmés

- Séparation claire **auth** (`User`) vs **profil** (`Person`).
- **Invariant** : `User` → `Person` obligatoire (`person_id` NOT NULL) ; `Person` peut exister sans `User`.
- One Source of Truth pour les données personnelles.
- Délégation propre `User → Person`.
- Côté `Person`, `has_one :user, dependent: :restrict_with_error` : pas de suppression incompatible tant qu’un compte web existe (archive / RGPD).
- `Payment` → `PaymentLine` polymorphique = un paiement peut regrouper adhésion + cotisation + don.
- Audit trail complet via `PaymentAuditLog` + UUID externe.
- Versioning sur `MembershipType` et `ContributionFormula` (`version`, `effective_from/until`, `change_reason`, `created_by_user_id`).

### Verdict d'audit (snapshot 2025-01-31)

| Dimension | Score | Commentaire |
| --- | --- | --- |
| Robustesse métier | 8 / 10 | Validations solides, quelques contradictions sur `Contribution` |
| Performance | 6 / 10 | Indexes composites manquants (cf. §4) |
| Maintenabilité | 7 / 10 | Concerns bien organisés, dualité `expired?` à clarifier |
| Testabilité | 6 / 10 | Polymorphisme `PaymentLine` + `skip_overlap_validation` augmentent le coût des tests |

## 2. Concerns

Douze concerns en place (`app/models/concerns/`) :

- `Dateable` — formatage et scopes temporels.
- `Priceable` — conversion centimes / euros.
- `Statusable` — humanization et helpers de statuts.
- `Categorizable` — humanization des catégories.
- `Humanizable` — humanization d'enums divers.
- `Roleable` — gestion des rôles utilisateur.
- `Versionable` — versioning (`MembershipType`, `ContributionFormula`).
- `SoftDeletable` — soft delete avec `deleted_at`.
- `EmailNormalizable` — normalisation email.
- `RateKindable` — tarif réduit / plein tarif.
- `PersonPaymentReporting` — agrégats paiements par personne.
- `BroadcastsDashboardStats` — diffusion des stats dashboard admin (Turbo Streams).

> ⚠️ `Validatable` et `Duplicatable` (détection/fusion de doublons), présents dans une version antérieure de ce document, **n'existent plus** dans `app/models/concerns/`. La fonctionnalité de doublons est en réflexion, voir [`../internal/todo.md`](../internal/todo.md).

### Tableau d'inclusion

> ⚠️ Tableau non ré-audité modèle par modèle lors de la dernière vérification (2026-08-10) — les colonnes reflètent l'état à 2026-05-01 et n'incluent pas les 4 concerns ajoutés depuis (`EmailNormalizable` est déjà présent, les 3 autres non). À recroiser avec le code avant de s'y fier pour une tâche précise.

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

`User`, `Person`, `Membership`, `Payment`, `PaymentLine`, `MembershipType`, `Contribution` — tous testés, à compléter selon les gaps.

#### Zone 1 — business logic prioritaire

- `ContributionFormula` — spec dédiée existe (`spec/models/contribution_formula_spec.rb`), critique pour le pricing.
- `Event` — partiel, ajouter edge cases.
- `AccountClaim` — workflow à couvrir.
- `Attendance` — logique quotidienne à couvrir.

#### Zone 1 — support

`MemberNumberHistory`, `PaymentAuditLog`, `PriceChangeLog` — tests d'audit, priorité basse.

#### Zone 2

- `AttendanceList` — logique quotidienne à finaliser.

#### Zone 3

`Blog`, `Tag`, `TagBlog` (CMS basique), `PriceCatalog`, `PriceEntry` (tarification, non urgent), `EventAttendee` (legacy), `Session` (Rails system).

### Services

#### Zone 1 — testés

`MemberManagementService`, `People::PaymentCreator`, `People::MembershipUpgrader`. À maintenir.

#### Zone 1 — non testés à couvrir

`Admin::PaymentsService`, `People::NewsletterSignup`.

#### Zone 2 — fonctionnels mais à stabiliser

`Web::UserRegistration`, `People::Register`, `People::PaymentUpdater`, `People::PaymentCanceller`, `People::PaymentRestorer`, `People::AttachUserToPerson`, `People::AccountLinker`, `UserManagement::UserDeleter`, `People::AccountMerger`.

> ✅ `app/services/event_management/` et `app/services/admin/operations/` (mentionnés comme orphelins/non-utilisés dans une version antérieure de ce document) ont depuis été supprimés — CRUD inline confirmé dans `Admin::EventsController`.

#### Zone 3

`People::PaymentRefund` (à concevoir).

### Contrôleurs

Voir [`controllers.md`](controllers.md) pour le détail. Résumé :

- **Zone 1** — admin CRUD critiques (`Admin::Members`, `Admin::Memberships`, `Admin::Payments`, `Admin::Events`, `Admin::Dashboard`) et auth/checkout publics (`Sessions`, `Registrations`, `Checkout`).
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

### 4.2 `Contribution` — validations `sessions_remaining` (à revérifier)

`app/models/contribution.rb` a désormais une validation `presence` standard (`if: :has_session_limit?`) **et** une validation custom `sessions_remaining_validation` qui revérifie présence/absence selon `is_pack10?`. Les deux se recoupent — à relire pour confirmer si la contradiction d'origine (default vs validation) persiste ou si c'est un doublon inoffensif.

### 4.3 `Membership#upgrade_to!` — `skip_overlap_validation` partout

`upgrade_to!` crée la nouvelle `Membership` sans désactiver l'ancienne immédiatement, ce qui forcerait une `no_overlapping_active_memberships`. Le contournement actuel est `skip_overlap_validation` répandu dans le code.

Action ciblée : inactiver l'ancienne dans la même transaction, puis créer la nouvelle, puis retirer `skip_overlap_validation`.

### 4.4 Indexes manquants — ✅ résolu

Les 5 indexes listés dans une version antérieure de ce document sont tous présents en base (`idx_payments_status_created`, `idx_memberships_circus_active` sur `[membership_type_id, status]`, `idx_payment_lines_amount`, `idx_contributions_person_status_exp`, `idx_contribution_formulas_type_duration`) — noms adaptés au renommage `phase3-model-rename`.

### 4.5 `Contribution.expires_at` nullable — ✅ résolu

`expires_at` est nullable en base et `validates :expires_at, presence: true, unless: :is_pack10?` en modèle : plus de hack `Time.current + 100.years` pour Pack 10.

### 4.6 `PaymentLine` — polymorphisme sans foreign key

Trade-off accepté (flexibilité > intégrité référentielle) mais à garder en tête lors des migrations. Voir [`../payments.md`](../payments.md) pour la dette `item_type:"Payment"` sur les dons.

### 4.7 Newsletter `newsletter_subscribed` sur `Person` — ✅ résolu

La colonne `people.newsletter_subscribed` a été supprimée (absente de `db/schema.rb`). Seul `newsletter_unsubscribe_token` reste sur `Person` ; le consentement newsletter vit désormais uniquement dans `NewsletterSubscriber`.

### 4.8 Versioning `MembershipType`/`ContributionFormula` — ✅ résolu

`Admin::MembershipTypesController#update` / `Admin::ContributionFormulasController#update` n'acceptent plus que des champs cosmétiques (`name`, `description`) — `price_cents` (et pour `ContributionFormula` : `duration`, `rate_kind`, `membership_type_id`, `sessions_count`, `validity_days`) sont retirés des strong params. Ces attributs identifient la ligne pour l'historique/la compta ; les muter en place réinterpréterait silencieusement des `Membership`/`Contribution` déjà achetées.

- **Changement de prix** : nouvelle action dédiée `change_price` (`create_price_change!`). Si la version courante n'a jamais été vendue (`memberships.empty?`/`contributions.empty?`), le prix est corrigé **en place** — pas de nouvelle ligne, catalogue propre. Si elle a déjà été vendue, la version courante est fermée (`effective_until`) et une nouvelle est créée ; les achats existants gardent leur ancien prix, inchangé.
- **Traçabilité** : chaque tentative (mergée ou versionnée) est loggée dans `PriceChangeLog` (table polymorphique `loggable`, pattern `PaymentAuditLog`) — `action: "merged"|"versioned"|"archived"`, `change_data` JSON (ancien/nouveau prix, raison), `user`. Permet de retrouver un tarif testé puis jamais vendu même quand il n'a pas généré de nouvelle ligne catalogue.
- **Archivage** : `archive!` ferme la version courante sans en ouvrir de nouvelle (exclusion de `current_versions`/`available_for`, donc plus proposée aux nouveaux achats) sans toucher aux `Membership`/`Contribution` déjà créées. Les pages index (`admin/membership_types`, `admin/contribution_formulas`) n'affichent que `current_versions` par défaut ; les versions fermées vont dans une section historique repliée.
- ✅ `ContributionFormula has_many :contributions, dependent: :destroy` (cascade de suppression sur des achats réels) remplacé par `dependent: :restrict_with_error`, aligné sur `MembershipType has_many :memberships, dependent: :restrict_with_error`. Supprimer une formule déjà achetée reste bloqué proprement.

## 5. Documentation liée

- [`overview.md`](overview.md) — architecture générale Person/User, RGPD, ViewComponents.
- [`services.md`](services.md) — catalogue des services `People::*`.
- [`controllers.md`](controllers.md) — état des contrôleurs.
- [`../domain/business_logic.md`](../domain/business_logic.md) — règles métier.
- [`../development/testing.md`](../development/testing.md) — guide tests.
