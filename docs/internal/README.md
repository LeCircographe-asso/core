# Documentation interne — Le Circographe

> **Statut** : internal
> **Public cible** : équipe dev / produit / ops
> **Versionné dans `dev`** : oui (le repo est privé, l'équipe est l'audience)

---

## Rôle de ce dossier

`docs/internal/` regroupe la documentation **utile à l'équipe** mais qui n'a pas vocation à être consultée par un contributeur externe ou présentée comme « source de vérité produit ».

Y vont :

- TODO et backlogs détaillés (`todo.md`, `optimizations_backlog.md`).
- Audits et diagnostics datés (`ux_audit_2025_01.md`).
- Plans de refonte ou de migration en cours, encore instables (`refonte.md`, `css_migration.md`).
- Procédures alternatives non testées en CI (`sqlite_deployment.md`).

N'y vont **pas** :

- Brouillons Cursor ou notes personnelles (→ `docs/_drafts/`, gitignored).
- Données sensibles : credentials, IPs serveurs hors GitHub Variables, mots de passe.
- Documentation produit stable (→ `docs/` racine, `docs/domain/`, `docs/architecture/`, etc.).
- Documentation legacy non normative (→ `docs/legacy/`).

## Différence avec `docs/legacy/`

| Dossier | Statut | Usage |
| --- | --- | --- |
| `docs/legacy/` | Historique non normatif | « On consulte si on veut comprendre le passé. » |
| `docs/internal/` | Vivant, en évolution | « On consulte pour avancer concrètement. » |

Un document peut migrer `internal/` → `legacy/` quand son sujet est clos
(ex. : un plan de migration une fois exécuté).

## Conventions

Chaque document de ce dossier doit avoir :

1. Un **header** déclarant `Statut: internal`, `Dernière vérification`, `Sources de vérité` (si applicable).
2. Une **date** (création ou dernière mise à jour).
3. Une **raison de présence dans `internal/`** (pourquoi pas en doc publique).

Voir le template global dans [`../README.md`](../README.md) section « Gouvernance documentaire ».

## Index

- `todo.md` — backlog produit et dette technique (fusion de `to-do.md` racine et `docs/TODO.md`).
- `optimizations_backlog.md` — backlog optimisations infra/UX.
- `refonte.md` — feuille de route refonte UX/UI (working document).
- `css_migration.md` — plan de migration CSS.
- `sqlite_deployment.md` — alternative bare-metal au flux Kamal (non testée en CI).
