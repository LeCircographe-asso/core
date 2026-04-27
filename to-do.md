# TODO - Le Circographe (Rails 8 / MVC)

Ordered from quick wins to long-term work. Each item can be handled incrementally.

## 0) Ground Rules (Architecture + MVC)
- Document the Person/User lifecycle and ownership rules.
- Enforce “Person is source of truth for identity + finance.”
- Ensure controllers remain thin: call services, render/redirect.
- Keep domain logic in models and workflows in services.
- Keep offer flows consistent (offer requires reason + audit trail).

## 1) Short (quick wins, low risk)
- Mark legacy views (e.g. `*_old.html.erb`) with `LEGACY` before removal. (done: `show_old.html.erb`)
- Admin users tabs: move to Stimulus tabs controller. (done)
- Extract shared partials for payments tab + tabs content. (done)
- Fix pack10 description copy (no expiration). (done in subscription plans list)
- Require `offer_reason` in UI when payment_method == offered. (done: membership + subscription purchase)
- Allow optional donation amount on membership/subscription purchase (single payment with donation line). (done)
- Remove “sessions remaining” for unlimited plans in UI (annual/trimester). (partial: admin user views + membership card)
- Ensure summary totals in admin payments match donation lines. (done)
- Update to-do list + docs as changes land. (ongoing)

## 2) Medium (flow consistency + integrity)
- Ensure admin registration uses `People::Register` only.
- Ensure account linking uses `People::AccountLinker` only.
- Ensure membership creation uses `People::MembershipCreator` only.
- Ensure subscription purchase uses `People::SubscriptionCreator` only.
- Ensure upgrades use `People::MembershipUpgrader` / `People::SubscriptionUpgrader`.
- Support Person without User (real-life registration first).
- Support User without Person (web-first signup).
- Provide explicit admin action to link User ↔ Person.
- Prevent implicit relinks when a Person already has a User.
- Show offer reason in payment history for offered payments.
- Enforce offer_reason on payments when payment_method == offered (admin edit too).
- Display offer reason in membership/subscription history when offered.
- Show donation line details in payment history.
- Ensure donation amount does not affect membership status logic.
- Ensure offer reason is stored/visible for subscriptions + membership upgrades.
- Add integrity checks for BookOfEntry (unlimited plans must have nil sessions_remaining).
- Add integrity check for payment_lines sum == payment total.
- Audit inline scripts for admin pages; replace with Stimulus.
- Normalize admin card spacing/typography for payments/memberships/subscriptions.
- Remove unused legacy components after confirming no references.

## 3) Documentation Alignment (medium)
- Add “Happy-path flows” docs (Register, Link, Membership purchase, Subscription purchase, Donation).
- Add “Data integrity rules” checklist (no orphans, no overlap, unlimited plan rules).
- Add “Role permissions” doc (who can offer, delete, link, anonymize).
- Maintain `knowledge/CURRENT_STATUS.md` as the index of truth.
 - Keep `docs/development/testing.md` + `docs/architecture/controllers.md` revalidated against current tests.

## 4) Tests (medium -> long)
- Service specs: Register, AccountLinker, MembershipCreator, SubscriptionCreator.
- Controller specs for admin flows (success + failure).
- ViewComponent specs for badges/contextual actions.
- Integrity specs for orphan queries.
- Request spec for health report and user archive deletion. (done)
- Fix SQLite CantOpenException in admin user creation request spec. (done)
- Request spec for offered membership/subscription (offer_reason required).
- Request spec for donation line creation in payments.
- System spec for admin user tabs + hash navigation.
- Integrity spec for unlimited plans with nil sessions_remaining.
- Spec for payment_lines sum == payment total.

## 5) Payments Accountability (longer)
- Remove any user_id references for payments (payments belong to Person). (partially done: User#destroy)
- Require `recorded_by` in all payment flows.
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
- Add report for book_of_entries with invalid sessions_remaining for unlimited plans.

## 8) Rollout Order
1. Health Report panel (visibility first). (done)
2. Fix invalid payment/user linking logic. (done: admin payment/donation links use person_id; removed user_id filter in payments service)
3. Force registration + linking through services.
4. Replace deletes with anonymization.
5. Clean legacy views.
6. Add/extend tests.
