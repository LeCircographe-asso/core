# 🚀 Guide Déploiement - Le Circographe

**Source de vérité (déploiement):** ce guide + `knowledge/OPTIMIZATIONS_TODO.md`  
**Historique:** les anciens guides sont archivés dans `knowledge/archive/`.

## Workflow Standard
```bash
# 1. Développement local
git checkout dev
# ... modifications ...

# 2. Staging
git checkout staging
git merge dev
git push origin staging
# → GitHub Actions 03 se déclenche

# 3. Production (après validation staging)
git checkout production  
git merge staging
git push origin production
# → GitHub Actions 05 se déclenche
```

## Tests de Validation
```bash
# Staging
curl -I https://staging.lecircographe.fr        # HTTP 200
curl -I https://staging.lecircographe.fr/up     # HTTP 200 (sans auth)

# Production  
curl -I https://lecircographe.fr                # HTTP 200
curl -I https://lecircographe.fr/up             # HTTP 200
```

## Variables GitHub Requises

### **Secrets (Organisation)**
- `RAILS_MASTER_KEY` - Clé de chiffrement Rails
- `SECRET_KEY_BASE` - Clé secrète Rails  
- `STAGING_PASSWORD` - Mot de passe auth HTTP Basic staging
- `SSH_PRIVATE_KEY` - Clé SSH pour déploiement VPS

### **Variables (Organisation)**
- `STAGING_SERVER_IP` - IP VPS staging
- `PRODUCTION_SERVER_IP` - IP VPS production

## Troubleshooting Rapide

| Erreur | Cause | Solution |
|--------|-------|----------|
| `Propshaft::MissingAssetError` | Assets non compilés | Vérifier Dockerfile + .dockerignore |
| `HTTP 401 sur /up` | Middleware bloque health checks | Exclure `/up` du middleware d'auth |
| `Exit 255` | Conteneur unhealthy | Vérifier logs + health checks |
| `Missing secret_key_base` | Credentials manquantes | Vérifier GitHub Secrets |

## Commandes Utiles
```bash
# Logs conteneur
docker logs <container-id> --tail 50

# Status déploiement
gh run list --limit 5
gh run view <run-id> --log

# Vérifier workflow en cours
gh run watch

# Rollback (si nécessaire)
kamal rollback -c config/deploy.staging.yml

# Accéder au conteneur
docker exec -it <container-id> bash
```

## Mode Maintenance (Production)

**Objectif:** maintenance activée par défaut, admin accès dashboard, healthcheck `/up` toujours OK.

### Comportement attendu
- `/up` → OK (healthcheck Kamal)
- `/sessions/new` → OK (login)
- `/admin/*` → OK si admin connecté
- Autres → 503 (page maintenance)

### Variables requises
```bash
MAINTENANCE_MODE=true
RAILS_ENV=production
SECRET_KEY_BASE=<secret>
RAILS_MASTER_KEY=<master_key>
```

### Middleware (rappel)
Fichier: `app/middleware/maintenance_mode_middleware.rb`
- Autoriser `/up`
- Autoriser `/sessions/new` et `/sessions`
- Autoriser `/admin/*` si session admin valide
- Sinon: page maintenance (503)

### Horaires sur page maintenance
Utiliser `Rails.cache.fetch("opening_hours")` avec fallback si indisponible.

## Importmap / Swiper Assets

- Depuis avril 2025, la tâche `assets:precompile` déclenche automatiquement `importmap:normalize_modules`.  
- Ce hook copie chaque module ES fingerprinté (`public/assets/_/Cfv2l5G4-*.js`) vers un alias sans digest (`public/assets/_/Cfv2l5G4.js`).  
- En local, `bin/rails_assets_reset` continue d'effectuer la même opération (étape 8) pour le confort des développeurs.

### Déploiement
- **Kamal / Docker build** : rien à ajouter, le hook est exécuté durant `bin/rails assets:precompile` dans l'image.  
- **VPS / serveurs** : après `kamal deploy`, on peut vérifier que les fichiers existent via `ls public/assets/_/`.  
- **Fallback manuel** : si besoin de forcer la régénération, exécuter `bin/rails importmap:normalize_modules`.

## Configuration Kamal Importante
```yaml
# config/deploy.staging.yml
proxy:
  ssl: true                    # Let's Encrypt automatique
  host: staging.lecircographe.fr
  app_port: 80                 # Port interne conteneur

volumes:
  - "circographe_staging_storage:/rails/storage"  # Données persistantes
  - "/srv/www/lecircographe_staging/log:/app/log" # Logs accessibles
```

**Note :** Les volumes garantissent que la base SQLite et les logs persistent entre déploiements.
