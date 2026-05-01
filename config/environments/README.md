# Configuration des Environnements - Le Circographe

## 🎯 Architecture Finale

### **Environnements Supportés**
- **Development** : Local (machine de développement)
- **Staging** : VPS Ionos (tests avant production)
- **Production** : VPS Ionos (site en ligne)

### **Fichiers de Configuration**
```
config/environments/
├── shared.rb          # ← Configuration commune à tous
├── development.rb     # ← Configuration locale
├── staging.rb         # ← Configuration VPS staging
├── production.rb      # ← Configuration VPS production
└── test.rb           # ← Configuration tests
```

### **Variables d'Environnement**
```
config/secrets/
├── env.development.example  # ← Template développement
├── env.staging.example      # ← Template staging
└── env.production.example   # ← Template production
```

## 🔧 Configuration par Environnement

### **Development (Local)**
- **Inscriptions publiques** : variable `PUBLIC_REGISTRATION_ENABLED` (initializer `config/initializers/public_registration.rb`). Valeurs `false` / `0` / `no` / `off` → désactive `/registration` et le lien « S'inscrire » ; la connexion reste disponible (mode vitrine). Sinon ou absent → inscriptions actives. Local : `.env` ou `.env.local` via `dotenv-rails`, puis redémarrer le serveur. Déploiement Kamal : `.kamal/secrets` (voir `.kamal/secrets.example`).
- **Assets** : Live reload, pas de précompilation
- **Base de données** : `storage/development.sqlite3`
- **Mail** : letter_opener (preview)
- **Logs** : Debug détaillé
- **SSL** : Désactivé

### **Staging (VPS)**
- **Assets** : Précompilés dans l'image Docker
- **Base de données** : `storage/staging.sqlite3` (volume Docker)
- **Mail** : Mailjet (test)
- **Logs** : Info level
- **SSL** : Activé + healthcheck /up exclu
- **Mode** : `STAGING_MODE=true`

### **Production (VPS)**
- **Assets** : Précompilés dans l'image Docker
- **Base de données** : `storage/production.sqlite3` (volume Docker)
- **Mail** : Mailjet (production)
- **Logs** : Info level
- **SSL** : Activé + healthcheck /up exclu
- **Mode** : Production standard

## 🐳 Docker Configuration

### **Build Time**
```dockerfile
# Compilation des assets en development (pas de credentials)
RUN SECRET_KEY_BASE_DUMMY=1 RAILS_ENV=development ./bin/rails assets:precompile
```

### **Runtime**
```yaml
# deploy.staging.yml
env:
  clear:
    RAILS_ENV: staging
    RAILS_MASTER_KEY: <staging-key>
```

## 🚀 Commandes de Déploiement

### **Setup Initial**
```bash
# Configuration développement
./scripts/setup-environment.sh development

# Configuration staging
./scripts/setup-environment.sh staging

# Configuration production
./scripts/setup-environment.sh production
```

### **Déploiement**
```bash
# Staging
git checkout staging
git merge dev
git push origin staging

# Production
git checkout production
git merge staging
git push origin production
```

## 🔐 Gestion des Secrets

### **Par Environnement**
- **Development** : Fichier `.env` local (pas versionné)
- **Staging** : Variables d'environnement GitHub Actions
- **Production** : Variables d'environnement GitHub Actions

### **Credentials Rails**
- **Development** : `development.yml.enc` + `development.key`
- **Staging** : `staging.yml.enc` + `staging.key`
- **Production** : `production.yml.enc` + `production.key`

## 📊 Monitoring et Debug

### **Logs**
```bash
# Staging
docker logs <container-id> --tail 100

# Production
docker logs <container-id> --tail 100
```

### **Console Rails**
```bash
# Staging
kamal app exec -c config/deploy.staging.yml --interactive "bundle exec rails console"

# Production
kamal app exec -c config/deploy.production.yml --interactive "bundle exec rails console"
```

### **Health Check**
```bash
# Vérifier le statut
curl -I https://staging.lecircographe.fr
curl -I https://lecircographe.fr
```

## ⚠️ Règles Importantes

1. **Jamais de credentials de production en local**
2. **Toujours tester sur staging avant production**
3. **Assets compilés en build, pas en runtime**
4. **Volumes Docker = données persistantes**
5. **Un secret = un environnement**
6. **Documentation toujours à jour**

## 📚 Documentation Complète

- **Architecture** : `docs/ARCHITECTURE_ENVIRONNEMENTS.md`
- **Déploiement** : `docs/DEPLOIEMENT_RAPIDE.md`
- **Setup** : `scripts/setup-environment.sh`
