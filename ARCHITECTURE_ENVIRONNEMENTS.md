# Architecture des Environnements - Le Circographe

## 🎯 Vue d'Ensemble

Notre application Rails 8.0 utilise 3 environnements distincts :

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   DEVELOPMENT   │    │     STAGING     │    │   PRODUCTION    │
│   (Local)       │    │  (VPS Ionos)    │    │  (VPS Ionos)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 📁 Structure des Configurations

### 1. **Environnements Rails**
```
config/environments/
├── development.rb    # ← Local (dev machine)
├── staging.rb        # ← VPS staging
├── production.rb     # ← VPS production
└── test.rb          # ← Tests unitaires
```

### 2. **Déploiements Kamal**
```
config/
├── deploy.staging.yml    # ← Configuration VPS staging
├── deploy.production.yml # ← Configuration VPS production
└── deploy.yml           # ← Template générique
```

### 3. **Credentials et Secrets**
```
config/
├── credentials/
│   ├── development.key
│   ├── staging.key
│   ├── production.key
│   └── master.key
├── credentials/
│   ├── development.yml.enc
│   ├── staging.yml.enc
│   └── production.yml.enc
└── secrets/
    ├── .env.development
    ├── .env.staging
    └── .env.production
```

## 🔄 Flux de Déploiement

### **Development (Local)**
```
Developer Machine
├── RAILS_ENV=development
├── Assets: Live reload (Tailwind)
├── Database: storage/development.sqlite3
├── Credentials: development.yml.enc
└── Mail: letter_opener (preview)
```

### **Staging (VPS)**
```
GitHub Actions → Docker Build → VPS Ionos
├── Build: RAILS_ENV=development (assets)
├── Runtime: RAILS_ENV=staging
├── Database: storage/staging.sqlite3 (volume Docker)
├── Credentials: staging.yml.enc
├── Domain: staging.lecircographe.fr
└── Mail: Mailjet (test)
```

### **Production (VPS)**
```
GitHub Actions → Docker Build → VPS Ionos
├── Build: RAILS_ENV=development (assets)
├── Runtime: RAILS_ENV=production
├── Database: storage/production.sqlite3 (volume Docker)
├── Credentials: production.yml.enc
├── Domain: lecircographe.fr
└── Mail: Mailjet (production)
```

## 🐳 Configuration Docker

### **Build Time (Dockerfile)**
```dockerfile
# Compilation des assets en development (pas de credentials requis)
RUN SECRET_KEY_BASE_DUMMY=1 RAILS_ENV=development ./bin/rails assets:precompile
```

### **Runtime (Kamal)**
```yaml
# deploy.staging.yml
env:
  clear:
    RAILS_ENV: staging
    RAILS_MASTER_KEY: <staging-key>
```

## 🔐 Gestion des Secrets

### **Par Environnement**
- **Development** : Clés locales, pas de secrets sensibles
- **Staging** : Secrets de test, BDD séparée
- **Production** : Secrets réels, BDD production

### **Variables d'Environnement**
```bash
# Development
RAILS_ENV=development
RAILS_MASTER_KEY=dev-key

# Staging  
RAILS_ENV=staging
RAILS_MASTER_KEY=staging-key
STAGING_MODE=true

# Production
RAILS_ENV=production
RAILS_MASTER_KEY=production-key
```

## 🗄️ Base de Données

### **Fichiers SQLite Séparés**
```
storage/
├── development.sqlite3     # ← Local
├── staging.sqlite3         # ← VPS staging (volume Docker)
├── production.sqlite3      # ← VPS production (volume Docker)
└── test.sqlite3           # ← Tests
```

### **Volumes Docker Persistants**
```yaml
# deploy.staging.yml
volumes:
  - "circographe_staging_storage:/rails/storage"

# deploy.production.yml  
volumes:
  - "circographe_production_storage:/rails/storage"
```

## 🎨 Assets et Frontend

### **Development**
- Tailwind CSS en live reload
- Assets servis directement
- Pas de précompilation

### **Staging/Production**
- Assets précompilés dans l'image Docker
- Propshaft pour la gestion des assets
- CDN-ready (fingerprinting)

## 📧 Configuration Email

### **Development**
```ruby
config.action_mailer.delivery_method = :letter_opener
```

### **Staging**
```ruby
config.action_mailer.delivery_method = :smtp
config.action_mailer.default_url_options = {
  host: "staging.lecircographe.fr",
  protocol: "https"
}
```

### **Production**
```ruby
config.action_mailer.delivery_method = :smtp
config.action_mailer.default_url_options = {
  host: "lecircographe.fr", 
  protocol: "https"
}
```

## 🚀 Commandes de Déploiement

### **Staging**
```bash
git checkout staging
git merge dev
git push origin staging
# → GitHub Actions déclenche le déploiement
```

### **Production**
```bash
git checkout production
git merge staging
git push origin production
# → GitHub Actions déclenche le déploiement
```

## 🔧 Maintenance

### **Rollback**
```bash
# Kamal rollback automatique
kamal rollback -c config/deploy.staging.yml
```

### **Logs**
```bash
# Voir les logs
docker logs <container-id> --tail 100
```

### **Debug**
```bash
# Accès au conteneur
docker exec -it <container-id> bash
bundle exec rails console
```

## ⚠️ Règles Importantes

1. **Jamais de credentials de production en local**
2. **Toujours tester sur staging avant production**
3. **Volumes Docker = données persistantes**
4. **Assets compilés en build, pas en runtime**
5. **Un secret = un environnement**
