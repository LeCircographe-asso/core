# Legacy — documentation non normative

Ce dossier regroupe des documents historiques qui ne sont **plus la source de vérité** du projet. Ils sont conservés pour traçabilité, pas pour être consultés au quotidien.

## Règles de lecture

- Le vocabulaire métier peut être ancien (`subscription`, `BookOfEntry`, etc.). La référence canonique reste [`docs/glossary.md`](../glossary.md).
- Les procédures techniques peuvent être obsolètes. Toujours croiser avec la documentation vivante avant d'agir.
- Pour le plan de migration vocabulaire, voir [`docs/migrations/vocabulary_migration.md`](../migrations/vocabulary_migration.md).

## Contenu

- [`production_deployment_plan.md`](production_deployment_plan.md) — snapshot
  one-shot du plan « mode maintenance + accès admin » de 2025-10-12. Pour la
  procédure courante, voir [`../operations/deployment.md`](../operations/deployment.md).
- [`incidents/oct_2025_lessons.md`](incidents/oct_2025_lessons.md) — synthèse
  des sessions de debug staging/production du 11–12 octobre 2025
  (`Propshaft::MissingAssetError`, `/up`, host authorization, optimisations
  Docker, mode maintenance).

À la racine du projet, [`docs/rake_archive/`](../rake_archive/) joue le même
rôle pour les Rake tasks de migration historique : à conserver, **ne jamais
relancer**.

## Pour la documentation vivante

- Index : [`docs/README.md`](../README.md)
- Lexique : [`docs/glossary.md`](../glossary.md)
- Modèle de domaine : [`docs/domain_model.md`](../domain_model.md)
- Paiements : [`docs/payments.md`](../payments.md)
- Migrations : [`docs/migrations/vocabulary_migration.md`](../migrations/vocabulary_migration.md)
