# 🧠 Base de Connaissance - Le Circographe

## 🚨 Règles Critiques (À NE JAMAIS OUBLIER)

### **1. Middleware d'Authentification**
```ruby
# TOUJOURS exclure /up des middlewares d'auth
if request.path == "/up"
  return @app.call(env)
end
```
**Pourquoi :** Kamal fait des health checks sur `/up`. HTTP 401 = conteneur arrêté.

### **2. Assets Propshaft**
- **Assets précompilés** requis en staging/prod
- **secret_key_base dummy** suffit pour build (pas de vraies credentials)
- **public/assets** inclus dans image Docker (pas dans .dockerignore)
```dockerfile
# Dockerfile - Asset compilation
RUN SECRET_KEY_BASE="a1b2c3...dummy...e1f2" RAILS_ENV=staging ./bin/rails assets:precompile
```

### **3. RAILS_ENV Configuration**
- **Build time :** Pas de `ENV RAILS_ENV` en dur dans Dockerfile
- **Runtime :** Configuré via Kamal (staging/production)
- **Flexibilité :** 1 image Docker pour 3 environnements

### **4. Rails Host Authorization + kamal-proxy**
```ruby
# Kamal-proxy utilise les IDs de conteneurs Docker comme hostnames
# Ex: f4753d38178e → Rails bloque par défaut
config.hosts.clear  # Autoriser tous les hosts pour Docker
```
**Pourquoi :** Kamal-proxy communication → `Blocked hosts` → healthcheck échoue

### **5. SSL Redirect + Healthcheck kamal-proxy**
```ruby
# kamal-proxy teste en HTTP, Rails force_ssl redirige tout en HTTPS
config.ssl_options = { 
  redirect: { exclude: ->(request) { request.path == "/up" } } 
}
```
**Pourquoi :** `/up` → 301 redirect → healthcheck échoue

## 🔧 Solutions Résolues

### **Propshaft::MissingAssetError**
**Cause :** Assets non compilés + config Rails incorrecte
**Solution :** 
- `config.public_file_server.enabled = true`
- `config.assets.paths << Rails.root.join("app", "assets", "builds")`
- Assets compilés en staging avec dummy key

### **HTTP 401 sur /up (Exit 255)**
**Cause :** StagingAuth bloque health checks Kamal
**Solution :** Exclure `/up` du middleware d'authentification

### **Blocked hosts: f4753d38178e:80**
**Cause :** Rails Host Authorization bloque kamal-proxy
**Solution :** `config.hosts.clear` dans staging.rb et production.rb

### **Healthcheck timeout (301 redirect)**
**Cause :** Rails force_ssl redirige `/up` en HTTPS
**Solution :** Exclure `/up` du SSL redirect avec `ssl_options`

### **SharedEnvironmentConfig Error**
**Cause :** Module non défini mais inclus
**Solution :** Supprimer `include SharedEnvironmentConfig`

## 📋 Architecture Découverte

### **1 Dockerfile → 3 Environnements**
- **Build :** Assets compilés avec dummy key
- **Runtime :** RAILS_ENV configuré via Kamal
- **Conditionnel :** Middleware activé selon ENV vars

### **Kamal Volumes (Persistance SQLite)**
```yaml
volumes:
  - "circographe_staging_storage:/rails/storage"  # Base SQLite
  - "/srv/www/lecircographe_staging/log:/app/log" # Logs
```
- **Garantit** : Base de données persiste entre déploiements
- **Important** : Sans volumes, SQLite serait recréé à chaque deploy

### **GitHub Secrets vs Variables**
- **Secrets :** `RAILS_MASTER_KEY`, `SECRET_KEY_BASE`, `STAGING_PASSWORD`, `SSH_PRIVATE_KEY`
- **Variables :** `STAGING_SERVER_IP`, `PRODUCTION_SERVER_IP`

### **Rails Credentials Flow**
```ruby
# staging.rb / production.rb
config.secret_key_base = ENV["SECRET_KEY_BASE"] || Rails.application.credentials.secret_key_base
```
- **Build time :** Dummy `SECRET_KEY_BASE` pour compilation assets
- **Runtime :** `RAILS_MASTER_KEY` déchiffre `credentials.yml.enc`
- **Kamal :** Exporte `RAILS_MASTER_KEY` + `SECRET_KEY_BASE` via `.kamal/secrets`
- **Ordre de priorité :** ENV var → credentials.yml.enc

## ⚠️ Pièges Évités

1. **Mélange d'environnements** (development pour build, production pour runtime)
2. **Credentials dans Dockerfile** (dummy key suffit pour build)
3. **Middleware sans exclusion /up** (bloque Kamal)
4. **Assets exclus de .dockerignore** (inclus dans image)
5. **RAILS_ENV en dur** (empêche flexibilité runtime)
6. **Rails Host Authorization** (bloque kamal-proxy container IDs)
7. **SSL redirect sur /up** (bloque healthcheck kamal-proxy)
8. **RAILS_MASTER_KEY non exporté** (Kamal ne peut pas injecter dans conteneur)
9. **Credentials sans fallback ENV** (rigide, pas de override possible)
