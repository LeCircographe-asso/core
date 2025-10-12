# Session Déploiement - Résolution Propshaft::MissingAssetError

**Date :** 12 Octobre 2025  
**Problème :** HTTP 500 - `Propshaft::MissingAssetError (The asset 'application.css' was not found in the load path.)`  
**Environnement :** Staging VPS Ionos avec Kamal + Docker + GitHub Actions

## 🔍 Diagnostic Initial

### Erreur observée :
```
Propshaft::MissingAssetError (The asset 'application.css' was not found in the load path.)
```

### Cause identifiée :
1. **Assets non compilés** dans l'image Docker
2. **Configuration Rails** incorrecte pour Propshaft
3. **Dockerfile** qui ne compile pas les assets correctement

## 🔧 Solutions Appliquées

### 1. Configuration Rails Assets

#### `config/environments/staging.rb` :
```ruby
# Avant
config.public_file_server.enabled = false  # ❌ Problématique

# Après
config.public_file_server.enabled = true   # ✅ Permet de servir les assets
config.assets.paths << Rails.root.join("app", "assets", "builds")  # ✅ Path Tailwind
```

#### `config/application.rb` :
```ruby
# Ajouté
config.assets.paths << Rails.root.join("app", "assets", "builds")  # ✅ Fallback pour tous les environnements
```

### 2. Docker Configuration

#### `.dockerignore` :
```bash
# Avant
/public/assets  # ❌ Excluait les assets compilés

# Après  
# /public/assets  # ✅ Commenté pour inclure les assets
```

#### `Dockerfile` - Évolution :

**Version qui fonctionnait (commit b3785e5) :**
```dockerfile
RUN SECRET_KEY_BASE_DUMMY=1 RAILS_ENV=development ./bin/rails assets:precompile
```

**Version qui échouait :**
```dockerfile
RUN SECRET_KEY_BASE="dummy_key_for_build_only_123456789" ./bin/rails assets:precompile
# ❌ Pas de RAILS_ENV → Rails charge production.rb → Demande vraies credentials
```

**Version finale (solution) :**
```dockerfile
# Suppression de ENV RAILS_ENV="production" en dur
ENV BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"

# Compilation avec RAILS_ENV=staging et dummy key valide
RUN SECRET_KEY_BASE="a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0e1f2" RAILS_ENV=staging ./bin/rails assets:precompile
```

### 3. Configuration Staging

#### `config/environments/staging.rb` - Support build :
```ruby
# Permet override ENV pour le build Docker
config.secret_key_base = ENV["SECRET_KEY_BASE"] || Rails.application.credentials.secret_key_base
```

## 🎯 Architecture Finale

### 1 Dockerfile pour 3 Environnements

#### Build Time (Dockerfile) :
- Assets compilés en `RAILS_ENV=staging`
- Dummy `SECRET_KEY_BASE` pour éviter les credentials pendant le build
- Pas de `RAILS_ENV` défini en dur → Configurable au runtime

#### Runtime (Kamal) :
- **Development** : `RAILS_ENV=development` (local)
- **Staging** : `RAILS_ENV=staging` (VPS via deploy.staging.yml)
- **Production** : `RAILS_ENV=production` (VPS via deploy.production.yml)

### Middleware StagingAuth

#### Configuration conditionnelle :
```ruby
# app/middleware/staging_auth.rb
def staging_environment?(request)
  request.host.start_with?("staging.") ||
  ENV["RAILS_ENV"] == "staging" ||
  ENV["STAGING_MODE"] == "true"
end
```

#### Activation :
- **Development** : `STAGING_MODE=false` → Auth désactivée
- **Staging** : `STAGING_MODE=true` → Auth activée (HTTP Basic)
- **Production** : `STAGING_MODE=false` → Auth désactivée

#### Configuration Kamal staging :
```yaml
env:
  secret:
    - RAILS_MASTER_KEY
    - SECRET_KEY_BASE
    - STAGING_PASSWORD  # Pour l'auth HTTP Basic
  clear:
    RAILS_ENV: staging
    STAGING_MODE: true
    STAGING_AUTH: true
```

## 🔐 Secrets GitHub

### Organisation Secrets (vérifiés) :
- ✅ `KAMAL_REGISTRY_PASSWORD` (last week)
- ✅ `RAILS_MASTER_KEY` (last week)  
- ✅ `SECRET_KEY_BASE` (2 days ago)
- ✅ `SSH_PRIVATE_KEY` (2 days ago)
- ✅ `STAGING_PASSWORD` (2 days ago)

### Organisation Variables :
- ✅ `PRODUCTION_SERVER_IP` : `82.165.63.129`
- ✅ `STAGING_SERVER_IP` : `82.165.63.129`

## 📋 Fichiers Modifiés

1. **`Dockerfile`** : Suppression `ENV RAILS_ENV="production"`, compilation assets staging
2. **`config/environments/staging.rb`** : Support `ENV["SECRET_KEY_BASE"]` pour build
3. **`config/application.rb`** : Ajout middleware `StagingAuth`
4. **`.dockerignore`** : Commenté `/public/assets` pour inclure assets compilés
5. **`Dockerfile.multi-stage`** : ❌ Supprimé (confusion éliminée)

## 🚀 Workflow de Déploiement

### Branches :
1. **`fix/dockerfile-asset-compilation`** → Corrections apportées
2. **`dev`** → Merge des corrections
3. **`staging`** → Déclenche workflow GitHub Actions 03

### GitHub Actions :
- **01 - CI & Tests** : Tests sur `dev`
- **03 - Staging Deploy** : Déploiement automatique sur `staging`

## ✅ Points Clés Appris

1. **Propshaft** nécessite assets précompilés en production/staging
2. **RAILS_ENV** défini en dur dans Dockerfile empêche la flexibilité runtime
3. **secret_key_base** dummy suffit pour la compilation d'assets
4. **Middleware conditionnel** permet 1 image pour 3 environnements
5. **GitHub Secrets** vs **Variables** : Secrets pour données sensibles, Variables pour configuration

## 🔄 Prochaines Étapes

1. Push branche `fix/dockerfile-asset-compilation`
2. Merge vers `dev`
3. Merge vers `staging` 
4. Surveillance workflow GitHub Actions 03
5. Test : `curl -I https://staging.lecircographe.fr` → HTTP 200 ✅

## 📚 Documentation Associée

- `docs/ARCHITECTURE_ENVIRONNEMENTS.md` : Architecture complète
- `config/secrets/env.*.example` : Exemples variables d'environnement
- `.github/workflows/03-staging-deploy.yml` : Workflow déploiement

---

**Status :** ✅ Corrections appliquées, prêt pour déploiement  
**Prochaine session :** Test déploiement et validation staging
