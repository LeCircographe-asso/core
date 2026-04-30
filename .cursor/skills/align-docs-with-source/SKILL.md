---
name: align-docs-with-source
description: >-
  Aligns documentation under docs/ with the current Rails codebase (models,
  schema, services, specs). Use when syncing docs after refactors, before
  merge to dev/main, or when the user asks to reconcile docs/ with source.
disable-model-invocation: true
---

# Align docs with source (Le Circographe)

## Goal

Keep Markdown under `docs/` consistent with **running code**, not aspirational text. Prefer **minimal edits** and **existing files** (no new docs unless the user asks).

## Sources of truth (read first)

1. `db/schema.rb` — columns, nullability, FKs.
2. Relevant `app/models/*.rb` (especially `User`, `Person`, `Payment`, `PaymentLine`).
3. Orchestration: `app/services/people/*.rb`, `app/services/account_claim_management/*.rb`.
4. Project lexicon: `docs/glossary.md`, `docs/migrations/vocabulary_migration.md`.
5. Cursor rules if identity/testing changed: `.cursor/rules/naming-rules.mdc`, `testing-auth-rules.mdc`.

## Checklist

- [ ] **Headers**: bump `Dernière vérification` on every touched public doc (`stable`).
- [ ] **User ↔ Person**: every `User` has a `Person` (`person_id` NOT NULL); a `Person` may have zero or one `User`. Linking via `People::AttachUserToPerson` / `People::AccountLinker`, not ad hoc controller assigns.
- [ ] **Payments / donations**: describe what `People::PaymentCreator` actually persists (`item_type` for donations); separate **legacy DB rows** from **current code** (see `docs/payments.md`, migrations `*donation*`).
- [ ] **Legacy vocabulary**: keep Ruby names (`BookOfEntry`, `SubscriptionPlan`, …) with **(cible : …)** per glossary — do not rename models in prose alone.
- [ ] **Cross-links**: `docs/README.md` index stays consistent with edited pages.

## Anti-patterns

- Copy-pasting old paragraphs after a refactor without grepping `app/`.
- Stating « optional User » where the DB requires `person_id`.
- Documenting `dependent: :nullify` on `Person` ↔ `User` if code uses `restrict_with_error`.

## Verification

After edits: quick grep in `docs/` for stale phrases (`User sans Person`, `réécrit.*Payment`, `dependent: :nullify` on User) and fix or contextualize.
