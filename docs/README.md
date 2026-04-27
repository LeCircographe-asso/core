# Documentation — Le Circographe

Index de la documentation Markdown du projet. Pour le démarrage et le déploiement, voir le [`README.md`](../README.md) à la racine.

> Une restructuration progressive est en cours. La structure cible est décrite dans [`migrations/vocabulary_migration.md`](migrations/vocabulary_migration.md).

## Domaine et vocabulaire

- [`glossary.md`](glossary.md) — lexique canonique FR/EN, termes interdits.
- [`domain_model.md`](domain_model.md) — diagramme Mermaid + responsabilités des agrégats.
- [`payments.md`](payments.md) — `Payment`, `PaymentLine`, `Donation` et la dette legacy `item_type:"Payment"`.
- [`domain/business_logic.md`](domain/business_logic.md) — règles métier complètes (adhésion, cotisation, paiements).

## Architecture

- [`architecture/overview.md`](architecture/overview.md) — Person/User, RGPD, ViewComponents.
- [`architecture/services.md`](architecture/services.md) — catalogue des services `People::*`.
- [`MODEL_EVALUATION.md`](MODEL_EVALUATION.md) — audit du modèle (Person-based, score 9/10).
- [`CONCERNS_ANALYSIS.md`](CONCERNS_ANALYSIS.md) — cartographie des 10 concerns.
- [`ZONES_CLASSIFICATION.md`](ZONES_CLASSIFICATION.md) — priorisation tests par zone.
- [`architecture/controllers.md`](architecture/controllers.md) — état des contrôleurs.

## Tests

- [`TDD_GUIDE.md`](TDD_GUIDE.md) — guide TDD complet (Red-Green-Refactor).
- [`TESTING_GUIDE.md`](TESTING_GUIDE.md) — couverture SimpleCov, gaps, plan.

## Frontend, UX et design

- [`TURBO_GUIDE.md`](TURBO_GUIDE.md) — diagnostic Turbo / Frames / Streams / Importmap.
- [`UX_GUIDE.md`](UX_GUIDE.md) — diagnostic écart back/front.
- [`REFONTE_CIRCOGRAPHE.md`](REFONTE_CIRCOGRAPHE.md) — feuille de route refonte UX/UI.
- [`ASSETS_LOCK.md`](ASSETS_LOCK.md) — règles Propshaft / Tailwind / Flowbite.
- [`design/color_system.md`](design/color_system.md) — palette, tokens, accessibilité.

## Operations

- [`knowledge/DEPLOYMENT_GUIDE.md`](knowledge/DEPLOYMENT_GUIDE.md) — workflow Kamal dev → staging → prod (source de vérité).
- [`knowledge/KNOWLEDGE_BASE.md`](knowledge/KNOWLEDGE_BASE.md) — règles or Kamal, `/up`, branches Git.
- [`knowledge/OPTIMIZATIONS_TODO.md`](knowledge/OPTIMIZATIONS_TODO.md) — backlog optimisations.
- [`PRODUCTION_SQLITE_DEPLOYMENT.md`](PRODUCTION_SQLITE_DEPLOYMENT.md) — alternative bare-metal (Ruby 4.0.1, SQLite, systemd).

## Migrations et legacy

- [`migrations/vocabulary_migration.md`](migrations/vocabulary_migration.md) — plan de renommage DDD-light, phases 0 → 4.
- [`legacy/README.md`](legacy/README.md) — documents historiques non normatifs.
- [`rake_archive/`](rake_archive/) — Rake tasks de migration one-shot, **ne plus exécuter**.

## Backlog

- [`TODO.md`](TODO.md) — backlog dev court terme (en cours de fusion avec `to-do.md` racine).
