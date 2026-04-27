# Guide de déploiement — Le Circographe

> Source de vérité **unique** pour le déploiement Kamal (staging + production).
> Fusion de l'ancien `knowledge/DEPLOYMENT_GUIDE.md` et des « règles d'or » de `knowledge/KNOWLEDGE_BASE.md`.
> Pour un déploiement bare-metal alternatif (sans Kamal), voir [`../internal/sqlite_deployment.md`](../internal/sqlite_deployment.md).
>
> **Branches actives** (cf. `.github/workflows/deploy-*.yml`) :
> `dev` (intégration) → `staging` (déploie staging) → `main` (déploie production).

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

### Secrets (organisation)

- `RAILS_MASTER_KEY` — clé de chiffrement Rails
- `SECRET_KEY_BASE` — clé secrète Rails
- `STAGING_PASSWORD` — mot de passe HTTP Basic staging
- `SSH_PRIVATE_KEY` — clé SSH déploiement VPS

### Variables (organisation)

- `STAGING_SERVER_IP`
- `PRODUCTION_SERVER_IP`

## 4. Règles critiques (à ne jamais oublier)

Ces règles sont issues de plusieurs incidents en staging/production. Les ignorer
casse les health checks Kamal ou rend le conteneur inaccessible.

### 4.1 Middleware d'authentification — toujours exclure `/up`

```ruby
return @app.call(env) if request.path == "/up"
```

**Pourquoi** : Kamal teste `/up` pour décider de la santé du conteneur.
Toute réponse `401`/`301` sur `/up` ⇒ conteneur considéré comme down ⇒ rollback.

### 4.2 Assets Propshaft

- Assets précompilés requis en staging/prod.
- Une `SECRET_KEY_BASE` dummy suffit pendant le build.
- `public/assets` doit être inclus dans l'image Docker (donc **absent** de `.dockerignore`).

```dockerfile
RUN SECRET_KEY_BASE="a1b2c3...dummy...e1f2" RAILS_ENV=staging \
    ./bin/rails assets:precompile
```

### 4.3 `RAILS_ENV` — build vs runtime

- **Build time** : pas de `ENV RAILS_ENV` en dur dans le `Dockerfile`.
- **Runtime** : configuré via Kamal (staging ou production).
- **Conséquence** : une seule image Docker pour 2 environnements applicatifs.

### 4.4 Host Authorization vs kamal-proxy

```ruby
# config/environments/{staging,production}.rb
config.hosts.clear  # autoriser les container IDs Docker (ex: f4753d38178e)
```

**Pourquoi** : kamal-proxy utilise les IDs de conteneur comme hostnames lors
des healthchecks. Sans `hosts.clear`, Rails renvoie `Blocked hosts`.

### 4.5 SSL redirect vs healthcheck

```ruby
config.ssl_options = {
  redirect: { exclude: ->(request) { request.path == "/up" } }
}
```

**Pourquoi** : kamal-proxy frappe `/up` en HTTP. Un redirect `301 → https`
fait échouer le healthcheck.

## 5. Troubleshooting rapide

| Erreur                              | Cause probable                       | Solution                                              |
|-------------------------------------|--------------------------------------|-------------------------------------------------------|
| `Propshaft::MissingAssetError`      | Assets non compilés                  | Vérifier `Dockerfile` + `.dockerignore` (cf. § 6.1)   |
| `HTTP 401 sur /up`                  | Middleware d'auth bloque healthcheck | Exclure `/up` du middleware (§ 4.1)                   |
| `Blocked hosts: f4753…:80`          | Host Authorization Rails             | `config.hosts.clear` (§ 4.4)                          |
| Healthcheck timeout (`301`)         | `force_ssl` redirige `/up`           | `ssl_options` exclude `/up` (§ 4.5)                   |
| `Exit 255`                          | Conteneur unhealthy                  | Vérifier logs + healthchecks                          |
| `Missing secret_key_base`           | Credentials manquantes               | Vérifier GitHub Secrets                               |
| `SharedEnvironmentConfig Error`     | Module inexistant inclus             | Supprimer `include SharedEnvironmentConfig`           |

## 6. Solutions historisées

### 6.1 `Propshaft::MissingAssetError`

- `config.public_file_server.enabled = true`
- `config.assets.paths << Rails.root.join("app", "assets", "builds")`
- Précompilation pendant le build avec dummy `SECRET_KEY_BASE`.

**Cas particulier (résolu 2025-10-12)** : `application.scss` ne génère pas
`application.css` avec Propshaft + DartSass. Solution : renommer en
`application.css` avec contenu CSS complet.

### 6.2 Pipeline CSS (rappel)

```
Tailwind CSS  → app/assets/tailwind/application.css → app/assets/builds/
DartSass      → app/assets/stylesheets/application.scss → ❌ ne génère pas .css
Propshaft     → cherche "application" → veut "application.css"
```

**Conclusion** : le fichier final doit s'appeler `application.css` pour Propshaft.

### 6.3 Fonts custom — bonnes pratiques

```css
@font-face {
  font-family: 'Circographe';
  src: font-url('Circographe-Regular.woff2') format('woff2');
  font-display: swap;
}
```

- `font-url()` → résolu par Rails vers `/assets/` après compilation.
- Formats multiples (`woff2`, `woff`, `otf`) pour compatibilité.
- `font-display: swap` pour éviter le flash de texte invisible.

## 7. Architecture déploiement

### 7.1 Une image, deux environnements

- Build : assets compilés avec dummy key.
- Runtime : `RAILS_ENV` injecté via Kamal.
- Middlewares activés conditionnellement selon variables d'env.

### 7.2 Volumes Kamal (persistance SQLite)

```yaml
volumes:
  - "circographe_staging_storage:/rails/storage"   # base SQLite
  - "/srv/www/lecircographe_staging/log:/app/log"  # logs accessibles
```

Sans volumes, la base SQLite serait recréée à chaque déploiement.

### 7.3 Flux des credentials Rails

```ruby
# staging.rb / production.rb
config.secret_key_base = ENV["SECRET_KEY_BASE"] ||
                         Rails.application.credentials.secret_key_base
```

- Build : dummy `SECRET_KEY_BASE` pour précompilation.
- Runtime : `RAILS_MASTER_KEY` déchiffre `credentials.yml.enc`.
- Kamal exporte `RAILS_MASTER_KEY` + `SECRET_KEY_BASE` via `.kamal/secrets`.
- Ordre de priorité : `ENV` → `credentials.yml.enc`.

### 7.4 Configuration Kamal type

```yaml
# config/deploy.staging.yml
proxy:
  ssl: true                    # Let's Encrypt automatique
  host: staging.lecircographe.fr
  app_port: 80                 # port interne conteneur

volumes:
  - "circographe_staging_storage:/rails/storage"
  - "/srv/www/lecircographe_staging/log:/app/log"
```

## 8. Mode maintenance (production)

**Objectif** : maintenance activée par défaut, admin garde l'accès, healthcheck `/up` toujours OK.

### Comportement attendu

- `/up` → OK (healthcheck Kamal).
- `/sessions/new` → OK (login).
- `/admin/*` → OK si admin connecté.
- Autres → `503` (page maintenance).

### Variables requises

```bash
MAINTENANCE_MODE=true
RAILS_ENV=production
SECRET_KEY_BASE=<secret>
RAILS_MASTER_KEY=<master_key>
```

### Middleware (rappel)

`app/middleware/maintenance_mode_middleware.rb`
- Autoriser `/up`.
- Autoriser `/sessions/new` et `/sessions`.
- Autoriser `/admin/*` si session admin valide.
- Sinon : page maintenance (`503`).

### Horaires sur la page de maintenance

Utiliser `Rails.cache.fetch("opening_hours")` avec fallback si cache indisponible.

## 9. Importmap & Swiper assets

- Depuis avril 2025, `assets:precompile` déclenche automatiquement
  `importmap:normalize_modules`.
- Le hook copie chaque module ES fingerprinté
  (`public/assets/_/Cfv2l5G4-*.js`) vers un alias sans digest
  (`public/assets/_/Cfv2l5G4.js`).
- En local, `bin/rails_assets_reset` exécute la même opération (étape 8).

### Vérification post-déploiement

- Kamal / Docker build : rien à ajouter, le hook tourne durant `assets:precompile`.
- VPS / serveurs : après `kamal deploy`, vérifier `ls public/assets/_/`.
- Fallback : `bin/rails importmap:normalize_modules`.

## 10. Commandes utiles

```bash
docker logs <container-id> --tail 50

gh run list --limit 5
gh run view <run-id> --log
gh run watch

kamal rollback -c config/deploy.staging.yml

docker exec -it <container-id> bash
```

## 11. Pièges évités (checklist)

1. Mélanger les environnements (build en `development`, runtime en `production`).
2. Inclure des credentials réelles dans le `Dockerfile` (la dummy key suffit pour le build).
3. Oublier d'exclure `/up` d'un middleware (§ 4.1).
4. Exclure `public/assets` du `.dockerignore` (doit y rester).
5. Coder `RAILS_ENV` en dur dans le `Dockerfile`.
6. Oublier `config.hosts.clear` (§ 4.4).
7. Forcer SSL sur `/up` (§ 4.5).
8. Ne pas exporter `RAILS_MASTER_KEY` côté Kamal.
9. Coder les credentials sans fallback `ENV`.

---

**Voir aussi :** [`../internal/optimizations_backlog.md`](../internal/optimizations_backlog.md) (backlog optimisation infra/Docker) · [`../internal/sqlite_deployment.md`](../internal/sqlite_deployment.md) (alternative bare-metal sans Kamal).
