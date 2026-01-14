# TODO - Le Circographe (Rails 8 / MVC)

This is the master, ordered checklist we will follow. Each item can be handled incrementally.

## 0) Ground Rules (Architecture + MVC)
- Document the Person/User lifecycle and ownership rules.
- Enforce “Person is source of truth for identity + finance.”
- Ensure controllers remain thin: call services, render/redirect.
- Keep domain logic in models and workflows in services.

## 1) Documentation Alignment
- Update `ARCHITECTURE_GUIDE.md` with Person/User lifecycle rules.
- Add a “Service entry points” section.
- Add an RGPD deletion policy section.

## 2) Single Entry Points (Services)
- Ensure admin registration uses `People::Register` only.
- Ensure account linking uses `People::AccountLinker` only.
- Ensure membership creation uses `People::MembershipCreator` only.
- Ensure subscription purchase uses `People::SubscriptionCreator` only.
- Ensure upgrades use `People::MembershipUpgrader` / `People::SubscriptionUpgrader`.

## 3) Person/User Lifecycle Rules
- Support Person without User (real-life registration first).
- Support User without Person (web-first signup).
- Provide explicit admin action to link User ↔ Person.
- Prevent implicit relinks when a Person already has a User.

## 4) Data Integrity & Orphan Prevention
- Add admin “Health Report” panel (read-only). (done)
  - users_without_person
  - people_without_user
  - duplicate_people_by_email
  - duplicate_people_by_phone
  - payments_without_person (should be zero)
- Add dashboard access to the Health Report. (done)
- Add admin actions to resolve:
  - Link user to person
  - Create missing user
  - Merge duplicates

## 5) RGPD-friendly Deletion
- Replace destructive deletes with anonymization flows.
- Prevent deleting a Person with payments/memberships.
- Add anonymization audit log with reason + actor.
 - Ensure soft-delete helpers exist for User reactivation flows. (done: with_deleted scope)
 - Soft-delete admin users instead of hard delete. (done: User#archive!)

## 6) Payments Accountability
- Remove any user_id references for payments (payments belong to Person). (partially done: User#destroy)
  - Require `recorded_by` in all payment flows.
  - Use “void/cancel” instead of delete.

## 7) Admin UI Cleanup (No Duplicated Views)
- Identify legacy views (e.g. `*_old.html.erb`).
- Choose a single canonical view per screen.
- Mark legacy views with a `LEGACY` comment before removal.
- Consolidate duplicated card layouts in admin pages.

## 8) Subscription/Membership Flow Consistency
- Separate “plan definition” vs “plan purchase.”
- Rename buttons/labels/routes to avoid confusion.
- Require `offer_reason` in UI when payment_method == offered.

## 9) Tests (Rails 8 + RSpec)
- Service specs: Register, AccountLinker, MembershipCreator, SubscriptionCreator.
- Controller specs for admin flows (success + failure).
- ViewComponent specs for badges/contextual actions.
- Integrity specs for orphan queries.
 - Request spec for health report and user archive deletion. (done)
 - Fix SQLite CantOpenException in admin user creation request spec. (done: switched to truncation cleanup for tests)

## 10) Rollout Order
1. Health Report panel (visibility first). (done)
2. Fix invalid payment/user linking logic. (in progress)
3. Force registration + linking through services.
4. Replace deletes with anonymization.
5. Clean legacy views.
6. Add/extend tests.
