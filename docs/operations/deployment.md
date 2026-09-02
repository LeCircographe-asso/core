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

git checkout main
git merge staging
git push origin main
# → .github/workflows/deploy-production.yml se déclenche
```

**Règle d'or — Aucune modification directe sur `staging` ni `main`.**
Toujours créer une branche dédiée :

```bash
git checkout -b fix/nom-du-probleme
# … travail …
git push origin fix/nom-du-probleme
# Merger ensuite vers dev → staging → main
```

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
