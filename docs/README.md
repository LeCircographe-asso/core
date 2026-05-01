# Documentation — Le Circographe

> **Statut** : stable
> **Public cible** : contributeur, équipe
> **Dernière vérification** : 2026-05-01
> **Sources de vérité** : structure réelle du dossier `docs/`.

Index de la documentation Markdown du projet. Pour le démarrage et le déploiement, voir le [`README.md`](../README.md) à la racine.

> Une restructuration progressive est en cours. La structure cible est décrite dans [`migrations/vocabulary_migration.md`](migrations/vocabulary_migration.md).

## Cartographie

```
docs/
  README.md             ← (ici) index, gouvernance, statuts
  glossary.md           lexique canonique
  domain_model.md       modèle de domaine
  payments.md           paiements, lignes, dons

  domain/               règles métier
  architecture/         modèles, services, contrôleurs
  development/          tests, Turbo, assets
  design/               design system stable
  operations/           déploiement (source de vérité ops)

  migrations/           plan DDD-light transitionnel
  legacy/               snapshots historiques non normatifs
  rake_archive/         Rake tasks one-shot historiques

  internal/             ← versionné, mais réservé équipe
                          (TODO, backlogs, audits datés, plans en cours)
  _drafts/              ← gitignored (brouillons Cursor / audits ponctuels)
```

---

## Gouvernance documentaire

### Statuts

Chaque document Markdown déclare un statut dans son header :

| Statut | Sens |
| --- | --- |
| `stable` | Vérifiée contre le code, vocabulaire canonique, prête pour `dev`. |
| `draft` | En cours d'écriture, ne doit pas être mergée dans `dev`. |
| `internal` | Utile équipe, non publique. Range dans `docs/internal/`. |
| `legacy` | Historique non normatif. Range dans `docs/legacy/`. |
| `deprecated` | Marquée pour suppression au prochain cycle. |

### Règles (résumé)

1. Toute doc publique a une **source de vérité code** (`app/`, `db/`, `config/`, `spec/`, `.github/`).
2. Toute doc métier utilise le **vocabulaire canonique** (voir [`glossary.md`](glossary.md)).
3. Les **TODO, backlogs, audits ponctuels** vont dans `docs/internal/` (versionné, équipe) ou `docs/_drafts/` (gitignored).
4. Toute doc **legacy** est isolée dans `docs/legacy/` avec encadré « non normatif ».
5. Toute **divergence code/doc** ouvre une issue ou une question — jamais d'auto-correction silencieuse.
6. Toute **suppression** est justifiée dans le commit message.

### Template de header

```markdown
# Titre du document

> **Statut** : stable | draft | internal | legacy | deprecated
> **Public cible** : contributeur | équipe dev | équipe ops | métier
> **Dernière vérification** : YYYY-MM-DD
> **Sources de vérité** :
> - `app/models/example.rb`
> - `db/schema.rb` (table `examples`)
>
> **À vérifier** :
> - [ ] Encore à jour après PR #123 ?
```

## Domaine et vocabulaire

- [`glossary.md`](glossary.md) — lexique canonique FR/EN, termes interdits.
- [`domain_model.md`](domain_model.md) — diagramme Mermaid + responsabilités des agrégats (invariant `User` → `Person`).
- [`payments.md`](payments.md) — `Payment`, `PaymentLine`, `Donation` et la dette legacy `item_type:"Payment"`.
- [`domain/business_logic.md`](domain/business_logic.md) — règles métier complètes (adhésion, cotisation, paiements).
- [`domain/happy_path_flows.md`](domain/happy_path_flows.md) — flux nominaux : Register, Link, Membership, Contribution, Donation.
- [`domain/data_integrity_rules.md`](domain/data_integrity_rules.md) — checklist des invariants + requêtes d'intégrité.
- [`domain/role_permissions.md`](domain/role_permissions.md) — matrice rôles/permissions + feature flags.

## Architecture

- [`architecture/overview.md`](architecture/overview.md) — Person/User, RGPD, ViewComponents.
- [`architecture/services.md`](architecture/services.md) — catalogue des services `People::*`.
- [`architecture/models.md`](architecture/models.md) — modèles, concerns, zones de stabilité, dettes techniques.
- [`architecture/controllers.md`](architecture/controllers.md) — état des contrôleurs.

## Tests

- [`development/testing.md`](development/testing.md) — guide TDD unifié (philosophie, setup, couverture, gaps, CI).

## Frontend, UX et design

- [`development/turbo.md`](development/turbo.md) — diagnostic Turbo / Frames / Streams / Importmap.
- [`development/assets.md`](development/assets.md) — règles Propshaft / Tailwind / Flowbite.
- [`design/color_system.md`](design/color_system.md) — palette, tokens, accessibilité.

## Operations

- [`operations/deployment.md`](operations/deployment.md) — workflow Kamal dev → staging → prod + règles d'or et troubleshooting (source de vérité).

## Migrations et legacy

- [`migrations/vocabulary_migration.md`](migrations/vocabulary_migration.md) — plan de renommage DDD-light, phases 0 → 4.
- [`legacy/README.md`](legacy/README.md) — documents historiques non normatifs.
- [`legacy/incidents/oct_2025_lessons.md`](legacy/incidents/oct_2025_lessons.md) — synthèse des incidents staging/production d'oct. 2025.
- [`legacy/production_deployment_plan.md`](legacy/production_deployment_plan.md) — snapshot du plan de mise en prod « mode maintenance ».
- [`rake_archive/`](rake_archive/) — Rake tasks de migration one-shot, **ne plus exécuter**.

## Documentation interne (équipe)

> Vivant, en évolution. Versionné dans `dev` mais hors de la doc publique. Voir [`internal/README.md`](internal/README.md).

- [`internal/todo.md`](internal/todo.md) — backlog produit + dette technique.
- [`internal/optimizations_backlog.md`](internal/optimizations_backlog.md) — backlog optimisations infra/UX.
- [`internal/ux_audit_2025_01.md`](internal/ux_audit_2025_01.md) — audit UX/UI daté 2025-01-31 (snapshot).
- [`internal/refonte.md`](internal/refonte.md) — feuille de route refonte UX/UI (working document).
- [`internal/css_migration.md`](internal/css_migration.md) — plan de migration CSS.
- [`internal/sqlite_deployment.md`](internal/sqlite_deployment.md) — alternative bare-metal au flux Kamal.
