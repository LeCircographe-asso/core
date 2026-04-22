# 🚀 Guide Déploiement - Le Circographe

**Statut actuel:** ⚠️ Historique (snapshot 2025-10-12).  
**Source de vérité:** `knowledge/DEPLOYMENT_GUIDE.md`.

---

**VPS**: Ionos Linux M - 82.165.63.129  
**Stack**: Rails 8.1.1 + Kamal 2.8.2 + kamal-proxy + Thruster

---

## 🐛 Debug: Architecture Découverte

### Architecture Réelle (Rails 8 + Thruster)
```
Internet (HTTPS)
    ↓
kamal-proxy:443 (SSL termination via Let's Encrypt)
    ↓ HTTP
Thruster:80 (Proxy Rails 8)
    ↓ HTTP
Puma:3000 (App Rails)
```

### Problème Initial Identifié
❌ **Erreur**: `dial tcp [::1]:3000: connect: connection refused`

### Investigation
1. **Hypothèse initiale**: Puma n'écoute pas sur port 80
   - ❌ FAUX: Puma écoute sur 3000 (normal avec Thruster)
   
2. **Découverte**: Rails 8 utilise Thruster
   - ✅ Thruster écoute sur port 80 (configuré via `PORT=80`)
   - ✅ Puma écoute sur port 3000 (par défaut)
   - ✅ `kamal-proxy` se connecte bien au conteneur sur port 80

3. **Problème réel**: Healthcheck retourne 301 au lieu de 200
   - Les logs montrent: `GET /up HTTP/1.1" 301`
   - Thruster ou Rails force une redirection HTTPS
   - `kamal-proxy` teste en HTTP → échec du healthcheck

### Solution
Configurer Rails pour accepter les healthchecks HTTP (nécessaire pour kamal-proxy).

---

## 📋 Configuration

### Kamal Staging (`config/deploy.staging.yml`)
```yaml
proxy:
  ssl: true  # Let's Encrypt auto
  host: staging.lecircographe.fr

env:
  secret: [RAILS_MASTER_KEY, SECRET_KEY_BASE]
  clear:
    RAILS_ENV: staging
    WEB_CONCURRENCY: 2
```

### Kamal Production (`config/deploy.production.yml`)
```yaml
proxy:
  ssl: true  # Let's Encrypt auto
  host: lecircographe.fr

env:
  secret: [RAILS_MASTER_KEY]
  clear:
    RAILS_ENV: production
    WEB_CONCURRENCY: 2
```

---

## 🔐 Secrets GitHub (Organization)

**Secrets:**
- `RAILS_MASTER_KEY` - Rails credentials
- `SECRET_KEY_BASE` - Rails secret  
- `SSH_PRIVATE_KEY` - Clé SSH VPS
- `STAGING_PASSWORD` - Password staging

**Variables:**
- `STAGING_SERVER_IP` = `82.165.63.129`
- `PRODUCTION_SERVER_IP` = `82.165.63.129`

---

## 🌐 DNS Requis

```
staging.lecircographe.fr → 82.165.63.129
lecircographe.fr → 82.165.63.129
www.lecircographe.fr → lecircographe.fr
```

---

## 🔧 VPS Setup (Une Fois)

```bash
# User deploy + Docker
adduser deploy
usermod -aG docker deploy
curl -fsSL https://get.docker.com | sh

# SSH key
mkdir -p /home/deploy/.ssh
# Copier votre clé publique dans authorized_keys
chown -R deploy:deploy /home/deploy/.ssh

# Firewall
ufw allow 22/tcp   # SSH
ufw allow 80/tcp   # HTTP
ufw allow 443/tcp  # HTTPS
ufw enable
```

---

## 🚀 Déploiement

### Staging
```bash
# PR dev → staging
gh pr create --base staging --head dev
gh pr merge --squash  # Auto-déploie via 03-staging-deploy.yml
```

### Production  
```bash
# Après validation staging
gh workflow run "04 - Promote to Main" --field confirm_promote=PROMOTE
```

---

## 🔍 Comment ça Marche

### Architecture
```
Internet → kamal-proxy (80/443) → Conteneurs (port 80)
           ├─ staging.lecircographe.fr [SSL auto]
           └─ lecircographe.fr [SSL auto]
```

### Environnements Rails
- **Development** (`development.rb`) → Dev local, port 3000
- **Test** (`test.rb`) → Tests automatisés, base de données temporaire  
- **Staging** (`staging.rb`) → Tests sur VPS, `staging.lecircographe.fr`
- **Production** (`production.rb`) → Production réelle, `lecircographe.fr`

**Note**: Chaque environnement a sa propre `secret_key_base` via `RAILS_MASTER_KEY`

### kamal-proxy
- **Un proxy unique** pour staging + prod
- **SSL automatique** Let's Encrypt (renouvellement auto)
- **Routing** par hostname (SNI)
- **Zero-downtime** natif
- **Healthcheck** GET /up (timeout 30s)

### Les Conteneurs
- Écoutent sur **port 80** (HTTP)
- **Pas de config SSL** (géré par kamal-proxy)
- Rails reçoit headers corrects (`X-Forwarded-Proto: https`)

---

## 📝 Logs

### Configuration des Logs (déjà dans deploy.yml)
```yaml
# Les logs Docker sont automatiques avec rotation
# Kamal ajoute par défaut:
logging:
  - "--log-opt"
  - "max-size=10m"  # Max 10MB par fichier log

# Logs applicatifs Rails → /app/log dans le conteneur
volumes:
  - "/srv/www/lecircographe_staging/log:/app/log"
```

### Accès aux Logs

**Temps réel (streaming):**
```bash
# Staging
kamal app logs -c config/deploy.staging.yml -f

# Production
kamal app logs -c config/deploy.production.yml -f

# Avec filtre (ex: erreurs uniquement)
kamal app logs -c config/deploy.staging.yml -f | grep ERROR
```

**Logs historiques:**
```bash
# 100 dernières lignes
kamal app logs -c config/deploy.staging.yml --lines 100

# Logs depuis 1h
kamal app logs -c config/deploy.staging.yml --since 1h

# Logs entre deux dates
kamal app logs -c config/deploy.staging.yml --since "2025-10-11 10:00" --until "2025-10-11 12:00"
```

**Sur le VPS directement:**
```bash
# Logs Docker (stdout/stderr)
ssh deploy@82.165.63.129 "docker logs circographe-staging-web-XXX"

# Logs Rails (fichiers)
ssh deploy@82.165.63.129 "tail -f /srv/www/lecircographe_staging/log/production.log"
ssh deploy@82.165.63.129 "tail -f /srv/www/lecircographe_staging/log/staging.log"

# Logs kamal-proxy
ssh deploy@82.165.63.129 "docker logs kamal-proxy"
```

---

## 🐛 Troubleshooting

### Diagnostic Kamal
```bash
# Status de l'app (staging)
kamal app status -c config/deploy.staging.yml

# Logs en temps réel (staging)
kamal app logs -c config/deploy.staging.yml -f

# Logs des 100 dernières lignes
kamal app logs -c config/deploy.staging.yml --lines 100

# Status de l'app (production)
kamal app status -c config/deploy.production.yml

# Logs production
kamal app logs -c config/deploy.production.yml -f
```

### Healthcheck échoue
```bash
# Via Kamal (recommandé)
kamal app logs -c config/deploy.staging.yml --lines 50

# Ou directement via SSH
ssh deploy@82.165.63.129 "docker ps -a | grep circographe"
ssh deploy@82.165.63.129 "docker logs circographe-staging-web-XXX"

# App DOIT écouter sur port 80 (pas 3000!)
```

### Erreur SSL
```bash
# Vérifier DNS propagé
dig staging.lecircographe.fr
dig lecircographe.fr

# Vérifier ports ouverts
ssh deploy@82.165.63.129 "ufw status"

# Logs proxy
ssh deploy@82.165.63.129 "docker logs kamal-proxy"
```

### Commandes Utiles
```bash
# Redémarrer l'app
kamal app restart -c config/deploy.staging.yml

# Arrêter l'app
kamal app stop -c config/deploy.staging.yml

# Voir les conteneurs
kamal app containers -c config/deploy.staging.yml

# Version déployée
kamal app version -c config/deploy.staging.yml

# Exécuter une commande dans le conteneur
kamal app exec -c config/deploy.staging.yml "bin/rails console"
```

---

## ✅ Checklist

**GitHub:**
- [ ] Secrets organization OK
- [ ] Variables organization OK

**VPS:**
- [ ] Docker installé
- [ ] User `deploy` + SSH OK
- [ ] Ports 22/80/443 ouverts
- [ ] Test: `ssh deploy@82.165.63.129`

**DNS:**
- [ ] Records A configurés
- [ ] DNS propagé (24-48h)

---

**Ref**: [Kamal 2 Docs](https://kamal-deploy.org/)
