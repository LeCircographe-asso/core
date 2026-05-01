# TODO — Le Circographe (Rails 8 / MVC)

> **Statut** : internal
> **Public cible** : équipe dev
> **Dernière mise à jour** : 2026-05-01
> **Provenance** : fusion de l'ancien `to-do.md` (racine) et `docs/TODO.md` (doublon).
>
> **Identity note (2026-05)** — tout `User` a une `Person` (création minimale si besoin, DB `users.person_id` NOT NULL). Pas de « User sans Person » en données. Voir résumé dans le [README](../../README.md) et la règle [naming-rules.mdc](../../.cursor/rules/naming-rules.mdc).
>
> **Vocabulary note (2026-05-01 — migration complète)** — les anciens noms `SubscriptionCreator`, `SubscriptionUpgrader`, `SubscriptionPlan`, `BookOfEntry` n'existent plus dans le code.
> Vocabulaire canonique actuel : `Contribution`, `ContributionFormula`, `People::ContributionCreator`, `People::ContributionUpgrader`.
> Exception légitime : `subscription` reste valide uniquement dans le contexte **newsletter**.
> Voir [`../glossary.md`](../glossary.md).

Ordered from quick wins to long-term work. Each item can be handled incrementally.

## 0b) Progressive Clarity Plan (PR by PR, simple -> métier)
- [x] **PR 1 — Similarity audit (safe)**: cartographier les doublons réels (`models/services/controllers/helpers/components`) et classer `fusionner / garder / reporter`.
  - DoD: tableau de décision court + liste des micro-PR candidates.
  - **Audit rapide exécuté (2026-05-01):**
    - `GARDER (ressemblance légitime)` : `People::ContributionCreator` vs `People::ContributionUpgrader` (même pattern service, intentions métier différentes).
    - `FUSIONNER/ALLÉGER (duplication de surface)` : `Admin::UsersController` (branches user/person + affectations manuelles de `person`), prioriser helpers privés/présenters.
    - `REPORTER (dette tolérable)` : coexistence `subscription_*` / `contribution_*` pendant migration vocabulaire.
    - `POINT D'ATTENTION` : `Admin::SubscriptionPlansController` reste nom legacy alors qu'il manipule `ContributionFormula`.
- [x] **PR 2 — Usage validation (safe)**: pour chaque candidat, vérifier usages, contrat d'entrée/sortie, effets de bord, couverture tests.
  - DoD: aucune fusion lancée sans preuve d'équivalence de comportement.
  - **Contrôles rapides exécutés (docs + code):**
    - `People::Register` est bien le point d'orchestration attendu pour création Person/User/Membership (`docs/architecture/services.md`, `app/services/people/register.rb`).
    - `Admin::UsersController` contient encore des liaisons/adaptations manuelles à clarifier (`association(:person).target`, `@user.person = ...`) ; à encapsuler côté service/presenter.
    - `Payment` et `PaymentLine` conservent des callbacks/effets de bord (audit/cache) acceptables mais à rendre plus explicites à moyen terme.
- [x] **PR 3 — Vocabulary alignment (safe)**: aligner le vocabulaire canonique sur les zones touchées (sans changement métier).
  - DoD: nouveaux changements lisibles en `Person/Membership/Contribution/Payment`.
  - **Alignement constaté / à finaliser:**
    - Aligné : services `People::Contribution*` et modèle `ContributionFormula` largement en place.
    - À éclaircir : nommage contrôleurs/routes admin legacy (`SubscriptionPlansController`, `SubscriptionsController`) vs vocabulaire cible.
    - À documenter explicitement : mapping stable `subscription_*` -> `contribution_*` dans les PR touchant admin + paiements.
- [x] **PR 4 — Email identity rule (medium)**: centraliser la règle transverse `Person.email` <-> `User.email_address` (cas autorisés/bloqués + messages clairs).
  - DoD: collisions cross-table non voulues bloquées; exceptions explicites et auditables.
- [x] **PR 5 — Callback visibility (medium)**: identifier 1 callback métier caché et le rendre explicite dans un service/flow sans refonte globale.
  - DoD: flux métier plus lisible, comportement identique.
- [x] **PR 6 — One focused extraction (medium+)**: extraire une mini-policy ciblée depuis `Person` (si gain clair), API inchangée.
  - DoD: diff courte, tests ciblés verts, rollback simple.

### 0b.1) Scopes à améliorer / points à éclaircir (simple, sans refonte)
- [x] **Scope A — Admin User flow readability**: réduire la complexité de `Admin::UsersController` (séparer adaptation vue de la logique métier).
  - 2026-05-01: extraction des branches `show` (person/user) et du flux `destroy` person en helpers privés dédiés, comportement inchangé couvert par `spec/requests/admin/users_spec.rb`.
- [x] **Scope B — Vocabulary boundary**: expliciter dans docs internes quels modules restent en legacy naming et pourquoi.
  - 2026-05-01: usages internes admin migrés vers routes/params `contribution_formula_*`; `subscription_*` reste surtout en nom de contrôleur legacy et quelques libellés/docs.
  - 2026-05-01 (suite): nouveau contrôleur canonique `Admin::ContributionFormulasController` en place; `Admin::SubscriptionPlansController` conservé temporairement comme shim de compat.
  - 2026-05-01 (inventaire inline):
    - runtime legacy restant: `Admin::SubscriptionPlansController` (shim), `Admin::SubscriptionsController` (nom legacy), `app/views/admin/users/new_subscription.html.erb`.
    - docs legacy restantes: `docs/architecture/controllers.md`, `docs/architecture/services.md`, `docs/domain/business_logic.md`, `docs/development/testing.md`.
    - ordre de retrait: 1) aligner docs 2) renommer/supprimer `new_subscription` 3) renommer `Admin::SubscriptionsController` 4) supprimer shim `Admin::SubscriptionPlansController` 5) nettoyer derniers `subscription_*` internes hors newsletter.
  - **2026-05-01 (complété):** Toutes les étapes de retrait exécutées — `new_subscription.html.erb` supprimé, `Admin::SubscriptionsController` → `Admin::ContributionsController`, shim `SubscriptionPlansController` supprimé, vues déplacées vers `admin/contribution_formulas/`, I18n keys migrés (`subscription_plans` → `contribution_formulas`, `subscriptions` → `contributions`), docs alignées, partiel `_attendance_subscription_options` → `_attendance_contribution_options`. Aucun référence `subscription_*` non-newsletter restante dans le runtime.
- [x] **Scope C — Identity consistency**: formaliser la règle cross-table email (`Person.email` / `User.email_address`) avant toute extraction supplémentaire.
  - 2026-05-01: policy centralisée `Identity::EmailPolicy` + validations `Person`/`User` + specs ciblées (models/services/forms) pour collisions cross-table.
- [x] **Scope D — Callback inventory**: lister callbacks métier de `Payment`, `Attendance`, `User` et classer `invariant technique` vs `workflow métier`.
  - 2026-05-01:
    - `Payment`: `before_create :generate_uuid` (invariant technique), `after_create :create_audit_log` (audit technique), `after_update` status/cache (audit + cohérence technique).
    - `Attendance`: `before_create :set_date_if_missing` (invariant technique), `after_create :decrement_contribution` (workflow métier présence/consommation).
    - `User`: `before_validation :ensure_person_for_new_record` (invariant d'architecture User->Person), `after_create :generate_password_reset_token` (sécurité technique), `welcome_send` sorti du callback et rendu explicite via `People::UserAccountCreator`.

## 0) Ground Rules (Architecture + MVC)
- Document the Person/User lifecycle and ownership rules. (done: `docs/domain/happy_path_flows.md` 2026-05-01)
- Enforce “Person is source of truth for identity + finance.”
- Ensure controllers remain thin: call services, render/redirect.
- Keep domain logic in models and workflows in services.
- Keep offer flows consistent (offer requires reason + audit trail).

## 1) Short (quick wins, low risk)
- **Public UI content audit (2026-05-01) — done.** See [`ux_audit_2025_01.md` § Audit contenu UI public — résolu](ux_audit_2025_01.md#audit-contenu-ui-public--résolu-2026-05-01) for the full diff: prix Trimestre 60 €, retrait « Adhésion soutien 20 € », dédoublonnage carte/bénévolat/newsletter, nettoyage `pages/le_lieu/*` mort, garde-fou `spec/requests/public_pages_content_spec.rb`.
- Mark legacy views (e.g. `*_old.html.erb`) with `LEGACY` before removal. (done: `show_old.html.erb`)
- Admin users tabs: move to Stimulus tabs controller. (done)
- Extract shared partials for payments tab + tabs content. (done)
- Fix pack10 description copy (no expiration). (done in contribution_formulas list)
- Require `offer_reason` in UI when payment_method == offered. (done: membership + contribution purchase)
- Allow optional donation amount on membership/contribution purchase (single payment with donation line). (done)
- Remove “sessions remaining” for unlimited plans in UI (annual/trimester). (partial: admin user views + membership card)
- Ensure summary totals in admin payments match donation lines. (done)
- Update to-do list + docs as changes land. (ongoing)
- **Feature flags (produit) + rôles** — Introduire un mécanisme unique pour activer/désactiver des capacités (ex. inscriptions publiques, **récupération de compte / reset mot de passe**), **en plus** des permissions par rôle (admin, bénévole, etc.) : flags = *est-ce que la fonctionnalité existe pour l’app ?*, rôles = *qui peut l’utiliser quand elle est ouverte ?*. Centraliser la lecture (ex. helper ou `FeatureFlags.*`), garde-fous **serveur** + masquage UI, pas seulement des variables d’env éparpillées. Premier pas déjà aligné avec `PUBLIC_REGISTRATION_ENABLED` ; étendre le même schéma aux autres actions. **Usage futur** : dashboard admin pour basculer certaines vues/actions (ex. bénévole) sans redéploiement — possible évolution vers table + cache plus tard.

## 2) Medium (flow consistency + integrity)
- [x] Ensure admin registration uses `People::Register` only. (`Admin::UserCreationForm` délègue à `People::Register` ; `UsersController#update` person appelle `People::Register` directement)
- [x] Ensure account linking goes through services — **no ad-hoc `user.person = …` in controllers.** (`@user.person =` restant dans `new`/`create` = view-prep sur `User.new` non persisté, acceptable ; writes réels passent par services)
- [x] Ensure membership creation uses `People::MembershipCreator` only. (exclusif dans `Admin::MembershipsController`)
- [x] Ensure contribution purchase uses `People::ContributionCreator` only. (exclusif dans `Admin::ContributionFormulasController`)
- [x] Ensure upgrades use `People::MembershipUpgrader` / `People::ContributionUpgrader`. (exclusifs dans leurs contrôleurs respectifs)
- [x] Support Person without User (real-life registration first). (par architecture : `Person` peut exister sans `User`)
- [x] Web signup: **chaque `User` a une `Person`** (stub minimale à la création). (NOT NULL DB + callback `ensure_person_for_new_record`)
- [x] Prevent implicit relinks when a Person already has a User. (`AttachUserToPerson` refuse si la Person cible a déjà un autre `User`)
- [x] Ensure donation amount does not affect membership status logic. (don = `PaymentLine` séparée, aucun effet sur `Membership`)
- Show offer reason in payment history for offered payments.
- Display offer reason in membership/contribution history when offered.
- Ensure offer reason is stored/visible for contributions + membership upgrades.
- Show donation line details in payment history.
- Enforce offer_reason on payments when payment_method == offered (admin edit too).
- Add integrity checks for `Contribution` (unlimited plans must have nil sessions_remaining).
- Add integrity check for payment_lines sum == payment total.
- Provide explicit admin action to link User ↔ Person. (partial: services prêts ; vérifier couverture UI + permissions)
- Audit inline scripts for admin pages; replace with Stimulus. (partial: 4 scripts restants — `users/edit`, `users/new`, `contribution_formulas/new`, `memberships/_create_membership`)
- Normalize admin card spacing/typography for payments/memberships/contributions.
- Remove unused legacy components after confirming no references.

## 3) Documentation Alignment (medium)
- [x] Add “Happy-path flows” docs (Register, Link, Membership purchase, Subscription purchase, Donation). — `docs/domain/happy_path_flows.md` (2026-05-01)
- [x] Add “Data integrity rules” checklist (no orphans, no overlap, unlimited plan rules). — `docs/domain/data_integrity_rules.md` (2026-05-01)
- [x] Add “Role permissions” doc (who can offer, delete, link, anonymize). — `docs/domain/role_permissions.md` (2026-05-01)
- [x] Maintain `docs/README.md` as the index of truth. — nouveaux docs indexés (2026-05-01)
- [x] Keep `docs/development/testing.md` + `docs/architecture/controllers.md` revalidated against current tests (invariant User→Person, RSpec-only, auth native Rails 8 résumés dans README / testing.md). — legacy `subscription_plan`/`BookOfEntry` refs nettoyées (2026-05-01)

## 4) Tests (medium -> long)
- [x] Request spec for health report and user archive deletion.
- [x] Fix SQLite CantOpenException in admin user creation request spec.
- Request spec for offered membership/contribution (offer_reason required).
- Request spec for donation line creation in payments.
- Integrity spec for unlimited plans with nil sessions_remaining.
- Spec for payment_lines sum == payment total.
- Integrity specs for orphan queries.
- Service specs: Register, AttachUserToPerson, AccountLinker, MembershipCreator, ContributionCreator.
- Controller specs for admin flows (success + failure).
- ViewComponent specs for badges/contextual actions.
- System spec for admin user tabs + hash navigation.

## 5) Payments Accountability (longer)
- Remove any user_id references for payments (payments belong to Person). (partial: `Admin::PaymentsController` line 322 filtre encore par `user_id`)
- Require `recorded_by` in all payment flows.
- Align legacy donation lines: aucune ligne ne doit rester avec `item_type: “Payment”` pour un don (canonique `Donation` ; migration de backfill existante — vérifier jeux de données réels et reporting).
- Use “void/cancel” instead of delete.
- Add donation receipt metadata (receipt_number, issued_at, issued_by_id).
- Add donation receipt PDF/email service.
- Add admin action to issue/resent receipts.
- Add donation reporting filters (date range, receipt status).

## 6) RGPD-friendly Deletion (longer)
- Replace destructive deletes with anonymization flows.
- Prevent deleting a Person with payments/memberships.
- Add anonymization audit log with reason + actor.
- Ensure soft-delete helpers exist for User reactivation flows. (done: with_deleted scope)
- Soft-delete admin users instead of hard delete. (done: User#archive!)

## 7) Data Consistency Jobs (longer)
- Add rake task to detect/repair missing payment_lines.
- Add rake task to backfill donation lines for legacy donations.
- Add report for contributions with invalid sessions_remaining for unlimited plans.

## 7b) Code cleanup tracked from doc audit (2026-04-27)
- [x] **Cleanup `EventManagement::*` orphans** — `app/services/event_management/` supprimé (dossier absent du dépôt). `Admin::EventsController` conserve le CRUD inline. (Source: doc audit 2026-04-27)

## 8) Rollout Order
1. Health Report panel (visibility first). (done)
2. Fix invalid payment/user linking logic. (done: admin payment/donation links use person_id; removed user_id filter in payments service)
3. Force registration + linking through services. (partial: `People::Register` sur chemins admin/form/web ; rattachement via `AttachUserToPerson` / `AccountLinker` ; auditer le reste des controllers)
4. Replace deletes with anonymization.
5. Clean legacy views.
6. Add/extend tests.
