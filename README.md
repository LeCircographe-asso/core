# Le Circographe

Application Rails 8 de gestion associative pour Le Circographe (adhésions, cotisations, paiements, présences, événements).

[![Version](https://img.shields.io/badge/version-0.5.9.1-blue)](#)
[![Rails](https://img.shields.io/badge/Rails-8.1.3-red)](#)
[![Ruby](https://img.shields.io/badge/Ruby-4.0.1-red)](#)
[![License](https://img.shields.io/badge/license-MIT-green)](#)

---

## Vocabulaire métier

Le projet utilise un vocabulaire DDD-light strict. **Avant toute contribution, lire :**

- [docs/glossary.md](docs/glossary.md) — lexique canonique (FR/EN), termes interdits.
- [docs/domain_model.md](docs/domain_model.md) — modèle de domaine (diagramme Mermaid).
- [docs/payments.md](docs/payments.md) — paiements, lignes, dons.
- [docs/migrations/vocabulary_migration.md](docs/migrations/vocabulary_migration.md) — plan de migration en cours.

> Résumé express : `Person` (CRM) ⟶ `User` (compte web optionnel) ⟶ `Membership` (adhésion annuelle) ⟶ `Contribution` (cotisation cirque, code legacy : `BookOfEntry`) selon une `ContributionFormula` (code legacy : `SubscriptionPlan`). Les paiements (`Payment`) regroupent une ou plusieurs `PaymentLine` (adhésion, cotisation, don).

---

## Démarrage

```bash
# Pré-requis : Ruby 4.0.1 (RVM/asdf) + SQLite + Foreman
bundle install
bin/rails db:prepare
bin/dev
```

Application disponible sur `http://localhost:3000`. Letter Opener Web (emails de dev) sur `http://localhost:3000/letter_opener`.

---

## Tests

```bash
bin/test                # suite complète + couverture
bin/test_fast           # models + services (rapide)
bin/test --no-coverage  # sans SimpleCov
```

---

## Déploiement

| Environnement | URL | Branche |
| --- | --- | --- |
| Development | `http://localhost:3000` | locale |
| Staging | `https://staging.lecircographe.fr` | `staging` |
| Production | `https://lecircographe.fr` | `main` |

Déploiement Kamal automatisé via GitHub Actions :

- Push sur `staging` → déploiement staging.
- Push sur `main` → déploiement production.
- Workflow « 04 - Promote to Main » : staging → main.

Scripts utilitaires :

```bash
./scripts/maintenance.sh [enable|disable|status] [staging|production]
./scripts/server-pull.sh [staging|production] [SERVER_IP]
```

---

## Pré-requis runtime

- Ruby `4.0.1`
- Rails `8.1.3`
- SQLite (multi-base : main / cache / queue / cable)
- Importmap + Propshaft (pas de Node.js)
- SolidQueue / SolidCache / SolidCable
- Docker + Kamal (déploiement)

---

## Documentation

L'index complet de la documentation se trouve dans [`docs/README.md`](docs/README.md). Points d'entrée recommandés :

- [`docs/glossary.md`](docs/glossary.md) — vocabulaire canonique.
- [`docs/domain/business_logic.md`](docs/domain/business_logic.md) — règles métier.
- [`docs/architecture/services.md`](docs/architecture/services.md) — catalogue des services.
- [`docs/TDD_GUIDE.md`](docs/TDD_GUIDE.md) — guide TDD.
- [`docs/knowledge/DEPLOYMENT_GUIDE.md`](docs/knowledge/DEPLOYMENT_GUIDE.md) — déploiement Kamal.

---

## Liens externes

- [Documentation Whimsical](https://whimsical.com/circograph-LAUT9hRLjkgEcGkLDKFPKV)
- [Wireframes](https://whimsical.com/wireframe-content-mapping-HYkmAuT9fc9BdZPB2vUvGc)
- [Schéma BDD](https://whimsical.com/diagram-database-J4Z17pjJ61YmVM9LK5jPMx)
- [User Stories](https://whimsical.com/user-stories-fonctionnal-mapping-GTkoaDv7mHwg8q8h3w5Mt4)

---

*Application développée pour Le Circographe.*
