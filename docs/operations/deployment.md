# Déploiement — Le Circographe

> **Statut** : stable | **Dernière vérification** : 2026-08-18
> **Stack** : Kamal + Docker + GitHub Actions | **Branches** : `dev` → `staging` → `main` (prod)

**Key insight:** Git push ≠ VPS deploy. `staging` branch updated ≠ CI/CD ran. If workflow fails, VPS keeps old image. Check `.github/workflows/deploy-{staging,production}.yml` logs.

## 1. Workflow Git standard

```bash
git checkout dev
# … modifications …

git checkout staging
git merge dev
git push origin staging
# → .github/workflows/deploy-staging.yml se déclenche

# Production : jamais de merge ni de push manuel sur main.
# GitHub → Actions → deploy-promote-to-main → Run workflow → saisir PROMOTE
# → merge staging dans main, puis lance .github/workflows/deploy-production.yml
# (refusé si le dernier deploy-staging n'a pas réussi)
```

Un push sur `main` ne déploie **pas** la production : seul le promote (ou un
`gh workflow run deploy-production.yml --ref main` volontaire) la déploie.

**Règle d'or — Aucune modification directe sur `staging` ni `main`.**
Toujours créer une branche dédiée :

```bash
git checkout -b fix/nom-du-probleme
# … travail …
git push origin fix/nom-du-probleme
# Merger ensuite vers dev → staging → main
```

<a id="migrations-et-donnees"></a>
### Migrations et données

Avant de pousser sur `staging` une branche qui contient une migration : `bin/docker-local upgrade` (image du VPS → ta copie de travail, données de démo, rapport comparé ; voir [`development/docker_local.md`](../development/docker_local.md#répéter-une-montée-de-version-upgrade)).

Écrire les migrations pour qu'un retour à l'image précédente reste possible **sans restaurer la base** :

- **En deux temps (expand / contract).** Version N : ajouter (colonne, table), copier les données, faire lire le nouveau champ par le code. Version N+1, une fois N en production : retirer l'ancien. Jamais de `remove_column`, `drop_table` ou renommage dans la même version que le code qui cesse de s'en servir : l'image N-1 doit pouvoir tourner sur la base migrée.
- **Pas de migration de données irréversible sans copie** : une migration qui réécrit ou supprime des lignes garde l'ancienne valeur (colonne ou table d'archive) jusqu'à la version suivante.
- **Colonne `null: false`** : avec une valeur par défaut, ou après un backfill dans une migration précédente.
- **Migrations de données : SQL, pas de modèles.** Un modèle peut changer plus tard et casser l'ancienne migration (`execute`/`update_all` plutôt que `Model.find_each { save }`).

## 2. Tests de validation post-déploiement

```bash
# Staging
curl -I https://staging.lecircographe.fr        # HTTP 200
curl -I https://staging.lecircographe.fr/up     # HTTP 200 (sans auth)

# Production
curl -I https://lecircographe.fr                # HTTP 200
curl -I https://lecircographe.fr/up             # HTTP 200
```

## 3. Variables GitHub requises

### Secrets (organisation) — ⚠️ SENSIBLES

**Où ajouter**: Settings → Secrets and variables → Actions → New organization secret.

| Secret | Source | Utilité | Scope |
|--------|--------|---------|-------|
| `RAILS_MASTER_KEY` | `config/master.key` (dev) | Déchiffre `credentials.yml.enc` en prod/staging | Tous workflows |
| `KAMAL_REGISTRY_PASSWORD` | GitHub Container Registry PAT | Pousse image Docker vers GHCR | Build + deploy |
| `SSH_PRIVATE_KEY` | Clé privée VPS deployer | Accès Kamal via SSH pour déployer | Deploy prod/staging |
| `SECRET_KEY_BASE` | `SecureRandom.hex(32)` unique | Fallback clé secrète si credentials fail | Staging/prod runtime |
| `STAGING_PASSWORD` | Mot de passe HTTP Basic staging | Protège `staging.lecircographe.fr` | Staging middleware |

**Vérification**: `gh secret list -R <owner/repo>` (listera les noms, pas les valeurs).

### Variables (organisation) — ℹ️ PUBLIQUES

**Où ajouter**: Settings → Secrets and variables → Actions → New organization variable.

| Variable | Valeur | Utilité |
|----------|--------|---------|
| `STAGING_SERVER_IP` | IP serveur staging | Kamal host deployment |
| `PRODUCTION_SERVER_IP` | IP serveur production | Kamal host deployment |

### `.kamal/secrets` — ⚠️ NE PAS COMMITTER

Ce fichier **doit rester localement** (déjà dans `.gitignore`). Structure actuelle est correcte:
```bash
KAMAL_REGISTRY_PASSWORD=$KAMAL_REGISTRY_PASSWORD  # référence env var GitHub
RAILS_MASTER_KEY=$(cat config/master.key)         # ou fallback env var
SECRET_KEY_BASE=${SECRET_KEY_BASE:-}              # optionnel locally
```

**Jamais**: `KAMAL_REGISTRY_PASSWORD=ghcr_abc123xyz` (hardcodé). Toujours `$VARIABLE`.

## 4. Règles Critiques (Kamal healthchecks)

| Règle | Raison | Fix |
|-------|--------|-----|
| `/up` toujours accessible (no auth, no redirects) | Kamal teste `/up` pour santé. 401/301 = down = rollback. | `return @app.call(env) if request.path == "/up"` |
| `config.hosts.clear` en staging/prod | Container ID Docker est hostname pour healthcheck | Ajout dans `config/environments/{staging,production}.rb` |
| `SSL exclude /up` | Force SSL redirige /up en 301 = healthcheck fail | `config.ssl_options = { redirect: { exclude: ->(req) { req.path == "/up" } } }` |
| Assets precompiled + `public/assets` in Docker | Missing assets = crash | `SECRET_KEY_BASE=dummy RAILS_ENV=staging bundle exec rails assets:precompile` |
| Single image, dual env | One image for staging + prod (RAILS_ENV at runtime) | Don’t hardcode RAILS_ENV in Dockerfile |

## 5. Troubleshooting

| Symptôme | Cause | Résolution |
|----------|-------|-----------|
| `Propshaft::MissingAssetError` | Assets not compiled | Check Dockerfile + `.dockerignore` |
| `HTTP 401/301 on /up` | Auth middleware blocks healthcheck | Exclude `/up` in middleware |
| `Blocked hosts: <container-id>` | Host Authorization issue | `config.hosts.clear` missing |
| Healthcheck timeout | SSL redirect on /up | Add exclude in `ssl_options` |
| `Exit 255` / no healthy container | App crashed during startup | Check logs in `.github/workflows/deploy-*.yml` |
| `Missing secret_key_base` | Credentials not loaded | Verify GitHub Secrets set |

<a id="donnees-au-deploiement"></a>
## 5bis. Données au déploiement : copie avant, rapport après

Trois filets, du moins cher au plus tardif : répétition locale avant de pousser (`bin/docker-local upgrade`, voir [`development/docker_local.md`](../development/docker_local.md)), copie de la base avant chaque déploiement, rapport des données réelles après.

### Copie de la base avant chaque déploiement

`.kamal/hooks/pre-deploy` tourne avant **chaque** `kamal deploy`, `redeploy` et `rollback` (staging et production, depuis GitHub Actions ou un poste). Il envoie [`ops/vps/db-snapshot`](../../ops/vps/db-snapshot) au VPS par `ssh deploy@<hôte> sh -s` (rien à installer sur le serveur), qui :

- fait un `sqlite3 .backup` de `storage/<env>.sqlite3` **dans le conteneur qui tourne** (copie cohérente même pendant des écritures) ;
- vérifie la copie (`PRAGMA integrity_check`), la compresse et la range dans `~deploy/backups/pre-deploy/<env>/<env>-<horodatage UTC>-<commande>-<version>.sqlite3.gz` (droits 600, **5 dernières gardées**) ;
- **arrête le déploiement** si la copie échoue. Premier déploiement (aucun conteneur) : rien à copier, le déploiement continue.

Hors du volume de l'app, exprès : le snapshot de nuit (`Backups::NightlySnapshotService`) archive ce volume, il ne doit pas embarquer ces copies. Elles ne couvrent que la base principale : Active Storage n'est pas touché par les migrations, et le snapshot de nuit le couvre.

Déployer malgré une copie impossible (incident, disque plein) : `kamal deploy --skip-hooks -c …`, à noter dans le compte rendu d'incident.

### Restaurer une copie (migration qui a abîmé les données)

Procédure répétée en local sur un volume jetable ; à faire calmement, une étape à la fois.

```bash
# 1. Choisir la copie prise juste avant le déploiement fautif
ssh circographe-deploy 'ls -lt ~/backups/pre-deploy/production'

# 2. Revenir à l'image précédente (le hook copie aussi l'état actuel avant : rien n'est perdu)
bin/kamal rollback <version_précédente> -c config/deploy.production.yml

# 3. Arrêter l'app, remettre la base, redémarrer
bin/kamal app stop -c config/deploy.production.yml
ssh circographe-deploy
  f=~/backups/pre-deploy/production/<fichier>.sqlite3.gz
  gunzip -c "$f" > /tmp/restore.sqlite3 && chmod 644 /tmp/restore.sqlite3
  img=$(docker ps -a --filter label=service=circographe-production --filter label=role=web --format '{{.Image}}' | head -n 1)
  docker run --rm -v circographe_production_storage:/rails/storage -v /tmp/restore.sqlite3:/restore.sqlite3:ro \
    --entrypoint sh "$img" -c 'cp /restore.sqlite3 storage/production.sqlite3 && rm -f storage/production.sqlite3-wal storage/production.sqlite3-shm'
  rm /tmp/restore.sqlite3; exit
bin/kamal app start -c config/deploy.production.yml
```

Staging : même chose avec `staging`. En production, Litestream repart sur une nouvelle génération de réplique après le remplacement du fichier : vérifier ses logs (`pro-applogs production grep litestream`). Les écritures faites entre la copie et la restauration (inscriptions, paiements) sont perdues : les relever d'abord dans la base abîmée si besoin.

### Rapport des données après chaque déploiement

Dernière étape des workflows `deploy-staging` / `deploy-production` : [`ops/vps/data-report`](../../ops/vps/data-report) lance [`ops/data_report.rb`](../../ops/data_report.rb) dans le conteneur déployé (lecture seule) et le résumé du run affiche lignes par table et règles d'intégrité ([`domain/data_integrity_rules.md`](../domain/data_integrity_rules.md)). Chaque anomalie devient une annotation ⚠️ du run ; l'étape n'échoue jamais (le déploiement est fait, et un échec déclencherait le rollback). Une anomalie en production : regarder la donnée réelle avant tout correctif, en se demandant si `bin/docker-local upgrade` aurait pu l'attraper (et enrichir les seeds de démo si oui).

## 6. Architecture Kamal

**One image → build once, run everywhere:**
- Build: precompile assets avec dummy `SECRET_KEY_BASE`
- Runtime: `RAILS_ENV` (staging/prod) + secrets via `.kamal/secrets`
- Credentials flow: `ENV["SECRET_KEY_BASE"]` → fallback `credentials.yml.enc`

**Volumes (persistence):**
```yaml
volumes:
  - "circographe_storage:/rails/storage"  # SQLite
  - "/srv/log:/app/log"                   # Logs
```

**Kamal proxy:** SSL via Let’s Encrypt, forwards to app port 80.

Un seul `kamal-proxy` est partagé par la production, le staging et Umami (`analytics`) : le redémarrer coupe les trois. Les workflows ne lancent donc **pas** `kamal proxy reboot` ; `kamal deploy` démarre le proxy s'il est absent et échoue avec un message explicite si sa version est inférieure au minimum de la gem Kamal. Pour monter de version, à faire à la main dans une fenêtre de maintenance :

```bash
bundle exec kamal proxy reboot -c config/deploy.production.yml   # coupure de quelques secondes sur tous les services
bundle exec kamal proxy details -c config/deploy.production.yml  # vérifier la version
ssh circographe-deploy 'docker exec kamal-proxy kamal-proxy list'   # les 3 routes doivent être là
```

`kamal proxy reboot -c config/deploy.production.yml` ne réenregistre que la production : les routes `circographe-staging-web` et `analytics` ne reviennent que grâce à l'état sauvegardé de kamal-proxy (volume `kamal-proxy-config`). Si l'une manque après le reboot : `bundle exec kamal deploy -c config/deploy.staging.yml` pour le staging, la commande `kamal-proxy deploy analytics` de `docs/operations/analytics.md` pour Umami.

Ce qui déclenche cette fenêtre de maintenance : Dependabot monte la gem `kamal` et la nouvelle version exige un kamal-proxy plus récent. Le prochain `kamal deploy` (staging ou production) échoue alors avec un message « kamal-proxy version … is too old » ; il ne repassera qu'après le reboot manuel ci-dessus.

**Secrets:** Only via `.kamal/secrets` (Kamal exports to container, never hardcoded).

## 8. Mode maintenance (production)

**Objectif** : tant que le site n'est pas lancé publiquement, tout est bloqué (`503`),
sans aucune exception pour le login ou l'admin — accès uniquement via console/SSH
tant que c'est actif.

### Comportement réel

- `/up` → OK (healthcheck Kamal).
- `/assets/*`, `/icon.png`, `/icon.svg` → OK (assets statiques nécessaires au
  rendu de la page de maintenance elle-même).
- `/manifest*`, `/service-worker*` → OK (évite les 401/erreurs PWA parasites).
- Tout le reste, **y compris `/session/new` et `/admin/*`** → `503` (page maintenance).

### Variables requises

`MAINTENANCE_MODE=true` est positionné par défaut dans `config/deploy.production.yml`
(`env.clear`), donc actif sur tout déploiement tant qu'il n'est pas explicitement
repassé à `false` (jour du lancement, avec `SEO_INDEXABLE=true` en même temps).

```bash
MAINTENANCE_MODE=true
RAILS_ENV=production
SECRET_KEY_BASE=<secret>
RAILS_MASTER_KEY=<master_key>
```

### Middleware (rappel)

`app/middleware/maintenance_mode_middleware.rb`
- Autoriser `/up`.
- Autoriser les assets statiques et fichiers PWA (voir ci-dessus).
- Sinon : page maintenance (`503`), sans exception pour login ou admin.

### Horaires sur la page de maintenance

Utiliser `Rails.cache.fetch("opening_hours")` avec fallback si cache indisponible.

## 9. Sécurité secrets & env vars (CRITIQUE)

### 9.1 Bonnes pratiques — checklist avant chaque déploiement

- [ ] **Jamais committer** de secrets réels (`config/master.key`, `.kamal/secrets` avec valeurs)
- [ ] `.gitignore` inclut: `config/master.key`, `.kamal/secrets`, `config/credentials/*.key`
- [ ] GitHub Secrets configurés (cf. § 3) — liste via `gh secret list`
- [ ] Credentials chiffrés: `bin/rails credentials:edit` en prod/staging = env vars only
- [ ] Aucun `ENV["SECRET"]` sans fallback `Rails.application.credentials.secret` (Rails 8.1 pattern)
- [ ] **Audit trimestriel**: `git log -p --all -- config/master.key .kamal/secrets` (doit être vide)
- [ ] Rotation clés annuelle : `bin/rails credentials:rotate` + update GitHub Secret

### 9.2 Leaks détectés — action immédiate

Si `config/master.key` ou autre secret leak en commit:
```bash
# 1. Regénérer la clé locale
bin/rails credentials:edit --force

# 2. Update GitHub Secret RAILS_MASTER_KEY avec la nouvelle
gh secret set RAILS_MASTER_KEY --body <new_key>

# 3. Redéployer prod/staging (Kamal va utiliser la nouvelle clé)
gh workflow run deploy-production.yml --ref main

# 4. Nettoyer git history (si possible)
git filter-repo --path config/master.key  # ou git-filter-branch (plus lent)
```

### 9.3 Env vars par environnement (à documenter ailleurs si extrait)

**Staging** (`config/environments/staging.rb`):
- `MAINTENANCE_MODE=true` (défaut)
- `RAILS_LOG_LEVEL=debug`
- `STAGING_PASSWORD` (HTTP Basic)

**Production** (`config/environments/production.rb`):
- `MAINTENANCE_MODE=true` par défaut (`config/deploy.production.yml`) tant que le site
  n'est pas lancé publiquement — voir section 8.
- `RAILS_LOG_LEVEL=info`
- Force SSL + HSTS

## 7. Known Issues & Lessons

**Fonts** (2025-10-12 incident): Propshaft searches for `application.css`. If using DartSass, `application.scss` doesn't generate `.css` — rename to `application.css`. Use `@font-face` with `font-url()` (resolved by Rails to `/assets/` after compile). Formats: woff2, woff, otf. Add `font-display: swap` to avoid text flash.

## 8bis. Maintenance Mode (rappel, voir section 8)

**Middleware:** `app/middleware/maintenance_mode_middleware.rb`
- Allow: `/up` (healthcheck)
- Allow: static assets (`/assets/*`, `/icon.png`, `/icon.svg`) and PWA files
- Else: 503 maintenance page — no exception for `/session/new` or `/admin/*`

**Opening hours:** `Rails.cache.fetch("opening_hours")` with fallback.

## 8. Commandes Utiles

```bash
# Logs
docker logs <container-id> --tail 50
docker exec -it <container-id> bash

# GitHub Actions
gh run list --limit 5
gh run view <run-id> --log
gh run watch

# Kamal
kamal rollback -c config/deploy.staging.yml
```

---

**See also:** [`../internal/sqlite_deployment.md`](../internal/sqlite_deployment.md) (bare-metal alternative).
