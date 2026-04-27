# Synthèse incidents staging/production — Octobre 2025

> **Statut** : legacy (snapshot daté 11–12 oct. 2025)
> **Public cible** : équipe ops (compréhension historique)
> **Dernière vérification** : 2026-04-27 (statut, pas le contenu)
> **Sources de vérité actuelles** : [`../../operations/deployment.md`](../../operations/deployment.md).
>
> Document **non normatif**. Synthèse de 7 archives historiques
> (`SESSION_LOG_2025-10-12`, `DEPLOYMENT_ANALYSIS`, `PERFORMANCE_REPORT`,
> `ANALYSIS_SUMMARY`, `DEPLOIEMENT`, `DEPLOIEMENT_RAPIDE`, `NEXT_STEPS`)
> condensées en leçons réutilisables.
>
> Ce fichier ne sert qu'à comprendre le **pourquoi** des règles d'or et garder une trace
> des arbitrages historiques.

## 1. Contexte

- Stack : Rails 8.1 + Kamal 2.8 + kamal-proxy + Thruster + Puma + SQLite.
- VPS : IONOS Linux M (`82.165.63.129`).
- Période d'investigation : sessions du 11 et 12 octobre 2025.
- État final : `Propshaft::MissingAssetError` résolu, déploiement staging stable, mode maintenance prêt pour la production.

## 2. Architecture constatée

```
Internet (HTTPS)
   ↓
kamal-proxy:443  (SSL termination via Let's Encrypt)
   ↓ HTTP
Thruster:80      (proxy HTTP/2 + compression Rails 8)
   ↓ HTTP
Puma:3000        (app Rails)
```

Le conteneur écoute sur le port `80` (Thruster). Ne **pas** chercher Puma sur 80 : c'est faux et c'est la cause racine de plusieurs faux diagnostics.

## 3. Incidents marquants

### 3.1 `Propshaft::MissingAssetError` après auth (HTTP 500 staging)

- **Symptôme** : login OK, puis `application.css was not found in the load path`.
- **Cause racine** : DartSass compilait `application.scss` vers `application.scss` (pas vers `.css`). Propshaft cherchait `application` et tombait sur le `.scss`, pas sur un `.css`.
- **Fausses pistes** :
  1. `config.assets.compile = true` seul → insuffisant.
  2. Mettre du contenu CSS dans le fichier `.scss` → DartSass le compile toujours en `.scss`.
- **Solution** : renommer `application.scss` → `application.css`, importer le contenu de `font.scss` dedans, supprimer `font.scss`. Propshaft reconnaît alors `application.css` dans le manifest.
- **Règle dérivée** : avec Propshaft + DartSass, l'entrypoint CSS doit s'appeler `.css`.

### 3.2 Healthcheck `/up` qui répond `301`

- **Symptôme** : Kamal marque le conteneur unhealthy alors que Rails démarre.
- **Cause racine** : `force_ssl` redirige systématiquement `/up` en HTTPS, mais kamal-proxy frappe en HTTP.
- **Solution** :

  ```ruby
  config.ssl_options = {
    redirect: { exclude: ->(request) { request.path == "/up" } }
  }
  ```

### 3.3 Healthcheck `/up` qui répond `401`

- **Symptôme** : staging répond `401` aux healthchecks après ajout de l'auth HTTP Basic.
- **Cause racine** : le middleware `StagingAuth` exige les credentials sur toutes les requêtes, y compris `/up`.
- **Solution** : court-circuiter `/up` en début de middleware :

  ```ruby
  return @app.call(env) if request.path == "/up"
  ```

### 3.4 `Blocked hosts: f4753d38178e:80`

- **Symptôme** : kamal-proxy fait du healthcheck via l'ID du conteneur, Rails Host Authorization refuse.
- **Solution** : `config.hosts.clear` dans `staging.rb` et `production.rb`.

### 3.5 `SharedEnvironmentConfig Error`

- **Cause racine** : un `include SharedEnvironmentConfig` traînait dans un environnement, sans le module défini.
- **Solution** : retirer l'`include`.

## 4. Erreurs de workflow Git constatées

- **Travail direct sur `staging`** lors de la session du 12 octobre → annulation manuelle (`git reset --hard HEAD~1`) puis création d'une branche `fix/...`.
- Règle interne adoptée depuis : **jamais de commit direct sur `dev`, `staging` ou `production`**. Toujours une branche `fix/`, `feature/`, `chore/` ou similaire, mergée via PR.

## 5. Optimisations Docker / CI testées

| Action                                                | Gain mesuré / estimé                              | Statut |
|-------------------------------------------------------|---------------------------------------------------|--------|
| Fixer la version de Bundler (`gem install bundler:X.Y.Z`) | ~10s par build, plus de warning lockfile          | Appliqué |
| Remplacer `docker login` par `docker/login-action@v3` | Crédentials chiffrées côté GitHub Actions         | Appliqué |
| `docker/build-push-action@v6` + cache GHA (`type=gha`)  | +2 min sur le 1ᵉʳ build, **-60 à -70 %** ensuite  | Appliqué |
| Réordonner `Dockerfile` (gems avant code applicatif)    | Cache layer gems réutilisable si `Gemfile.lock` inchangé | Appliqué |
| Nettoyage agressif des gems (`/test`, `/spec`, etc.)    | -10 à 20 MB sur l'image                           | Appliqué |
| Activation YJIT + jemalloc + Bootsnap                   | Boot time + RAM optimisés                         | Appliqué |
| Configuration d'un credential helper Docker sur le VPS  | Crédentials chiffrées côté serveur                | **À faire** |

### Métriques avant/après (run #18444855888 vs #18446080894)

- Avant cache : ~6 min par déploiement.
- Premier build avec cache : ~8 min (création du cache).
- Builds suivants (changement code uniquement) : ~2 à 3 min.
- ROI sur 50 déploiements : ~5 h → ~1 h 46 (≈ -65 %).

## 6. Mode maintenance production (préparation)

- Variable d'env `MAINTENANCE_MODE=true` lue par `app/middleware/maintenance_mode_middleware.rb`.
- Comportement attendu :
  - `/up` : `200` (healthcheck Kamal).
  - `/sessions/new`, `/sessions` : `200` (login admin possible).
  - `/admin/*` : `200` si session admin valide.
  - Tout le reste : `503` (page maintenance avec horaires d'ouverture lus depuis `Rails.cache.fetch("opening_hours")` + fallback).
- Désactivation prévue par `gh variable set MAINTENANCE_MODE --body "false"` puis redéploiement.

Le détail complet (code middleware, rendu HTML des horaires) reste dans
[`../production_deployment_plan.md`](../production_deployment_plan.md), conservé comme snapshot de la décision.

## 7. Warnings non bloquants observés

- `Removed sourceMappingURL comment for missing asset 'swiper-bundle.min.js.map'`
- `Removed sourceMappingURL comment for missing asset 'flowbite.min.js.map'`
- `Unable to resolve 'image.svg' for missing asset 'image.svg' in tailwind.css`
- `WARN Missing compatible builder, so creating a new one first` (Kamal recrée son builder Docker — comportement normal).

→ **Aucune action requise** en production. Ajouter les `.map` côté `vendor/javascript/` uniquement si on veut debugger côté navigateur.

## 8. Décisions adoptées suite à ces incidents

1. Ajout de la section « Règles critiques » dans
   [`../../operations/deployment.md`](../../operations/deployment.md) (les règles
   décrites en §3 sont devenues les §4.1 à §4.5 de ce guide).
2. Migration des `Sprockets`-isms restants vers Propshaft (séparation
   `application.css` / `tailwind.css` / `application.scss`).
3. Adoption du backlog
   [`../../internal/optimizations_backlog.md`](../../internal/optimizations_backlog.md)
   pour suivre les optimisations Docker/CI/sécurité encore en attente.
4. Workflow Git strict (`dev` → `staging` → `production`, jamais en direct).

## 9. Pourquoi conserver ce document

Les 7 archives originales étaient redondantes (4 d'entre elles racontent la
même session sous des angles différents) et utilisaient des noms incohérents
(`KNOWLEDGE_BASE`, `DEPLOIEMENT`, `DEPLOIEMENT_RAPIDE`, …). Cette synthèse
remplace l'ensemble. Si l'un de ces 7 fichiers est nécessaire pour audit
historique, l'historique git le restitue.

---

**Sources fusionnées (toutes supprimées de `docs/knowledge/archive/`)** :
`SESSION_LOG_2025-10-12.md`, `DEPLOYMENT_ANALYSIS.md`, `PERFORMANCE_REPORT.md`,
`ANALYSIS_SUMMARY.md`, `DEPLOIEMENT.md`, `DEPLOIEMENT_RAPIDE.md`, `NEXT_STEPS.md`.
