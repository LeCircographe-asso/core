# Legacy — documentation non normative

Ce dossier regroupe des documents historiques qui ne sont **plus la source de vérité** du projet. Ils sont conservés pour traçabilité, pas pour être consultés au quotidien.

## Règles de lecture

- Le vocabulaire métier peut être ancien (`subscription`, `BookOfEntry`, etc.). La référence canonique reste [`docs/glossary.md`](../glossary.md).
- Les procédures techniques peuvent être obsolètes. Toujours croiser avec la documentation vivante avant d'agir.
- Pour le plan de migration vocabulaire, voir [`docs/migrations/vocabulary_migration.md`](../migrations/vocabulary_migration.md).

## Contenu

Au fur et à mesure de la restructuration documentaire, ce dossier accueillera :

- les snapshots de plans de déploiement « one-shot » (mode maintenance, etc.) ;
- les comptes-rendus d'incidents ou de sessions de debug datés ;
- les anciennes notes de migration encore référencées par certains fichiers.

À la racine du projet, [`docs/rake_archive/`](../rake_archive/) joue le même rôle pour les Rake tasks de migration historique : à conserver, **ne jamais relancer**.

## Pour la documentation vivante

- Index : [`docs/README.md`](../README.md)
- Lexique : [`docs/glossary.md`](../glossary.md)
- Modèle de domaine : [`docs/domain_model.md`](../domain_model.md)
- Paiements : [`docs/payments.md`](../payments.md)
- Migrations : [`docs/migrations/vocabulary_migration.md`](../migrations/vocabulary_migration.md)
