# 🎯 Prochaines Étapes - À Faire Chez Toi

**Date :** 2025-10-12  
**Contexte :** Session laptop terminée, continuation sur PC fixe

---

## ✅ **Ce qui est fait (Laptop)**

### **Problèmes Résolus :**
- ✅ `Propshaft::MissingAssetError` (HTTP 500) → Résolu
- ✅ CSS compilation en staging → Fonctionne
- ✅ Workflow Git corrigé → Branches dédiées
- ✅ Documentation organisée → Dossier `knowledge/`
- ✅ Branches synchronisées → `dev` et `staging` à jour

### **Optimisations Appliquées :**
- ✅ Docker build cache configuré
- ✅ Bundler version fixée
- ✅ Rack CVE corrigées (3.2.3)
- ✅ Bundle audit intégré
- ✅ Jemalloc activé

---

## 🚀 **Prochaine Mission : Production avec Maintenance**

### **Objectif :**
Déployer le site en production avec :
1. **Mode maintenance activé** par défaut
2. **Admin peut se connecter** et modifier les horaires
3. **Visiteurs voient** page maintenance + horaires
4. **Healthcheck Kamal** fonctionne toujours

### **Plan d'Action :**

#### **Étape 1 : Récupérer le Travail (PC Fixe)**
```bash
cd /path/to/Final_Project/core
git checkout dev
git pull origin dev

# Vérifier que tout est là
ls -la knowledge/
git log --oneline -5
```

#### **Étape 2 : Créer Branche Feature**
```bash
git checkout -b feature/production-maintenance-mode
```

#### **Étape 3 : Modifier le Middleware**

**Fichier :** `app/middleware/maintenance_mode_middleware.rb`

**Modifications à faire :**
1. Autoriser `/sessions/new` (page login)
2. Autoriser `/admin/*` si session admin valide
3. Afficher les horaires sur la page maintenance

**Code à ajouter :**
```ruby
def admin_access?(env, request)
  # Autoriser page login
  return true if request.path == "/sessions/new" || request.path == "/sessions"
  
  # Autoriser routes admin si session valide
  if request.path.start_with?("/admin")
    session = load_session(env)
    return session && session["user_id"].present?
  end
  
  false
end

def load_session(env)
  session_key = Rails.application.config.session_options[:key] || "_circographe_session"
  cookie_jar = ActionDispatch::Cookies::CookieJar.build(
    Rack::Request.new(env),
    {}
  )
  
  session_data = cookie_jar.encrypted[session_key]
  session_data.is_a?(Hash) ? session_data : {}
rescue StandardError
  {}
end
```

**Voir détails complets dans :** `knowledge/PRODUCTION_DEPLOYMENT_PLAN.md`

#### **Étape 4 : Afficher Horaires sur Page Maintenance**

**Ajouter dans `maintenance_response` :**
```ruby
def maintenance_response
  opening_hours_html = render_opening_hours
  
  body = <<~HTML
    <!-- ... head existant ... -->
    <body>
      <div class="card">
        <!-- ... contenu existant ... -->
        
        #{opening_hours_html}
        
        <!-- ... réseaux sociaux ... -->
      </div>
    </body>
  HTML
  
  [ 503, headers, [ body ] ]
end

def render_opening_hours
  hours = Rails.cache.fetch("opening_hours") || default_opening_hours
  
  <<~HTML
    <div style="margin: 24px 0; padding: 20px; background: #f8fafc; border-radius: 12px;">
      <h2 style="margin: 0 0 16px; font-size: 1.3rem; text-align: center;">📅 Nos Horaires</h2>
      <div style="display: grid; gap: 8px;">
        #{hours.map { |day, time| 
          "<div style='display: flex; justify-content: space-between;'>
            <strong>#{day.capitalize} :</strong> 
            <span>#{time}</span>
          </div>"
        }.join}
      </div>
    </div>
  HTML
end
```

#### **Étape 5 : Tester Localement**
```bash
# Activer maintenance en local
MAINTENANCE_MODE=true RAILS_ENV=production rails s

# Tester :
# 1. http://localhost:3000 → Page maintenance
# 2. http://localhost:3000/sessions/new → Login accessible
# 3. Se connecter admin → Dashboard accessible
# 4. Modifier horaires → Sauvegarde OK
# 5. Recharger page maintenance → Horaires mis à jour
```

#### **Étape 6 : Configurer GitHub Secrets Production**
```bash
# Vérifier secrets existants
gh secret list

# Ajouter si manquant
gh secret set MAINTENANCE_MODE --body "true"
gh secret set RAILS_MASTER_KEY --body "<votre_master_key>"
gh secret set SECRET_KEY_BASE --body "<votre_secret_key_base>"
```

#### **Étape 7 : Déployer en Production**
```bash
# Commit et push
git add .
git commit -m "feat: Add admin bypass for maintenance mode with opening hours display"
git push origin feature/production-maintenance-mode

# Merger vers main (ou production)
git checkout main
git pull origin main
git merge feature/production-maintenance-mode
git push origin main

# → GitHub Actions workflow 05 se déclenche automatiquement
```

#### **Étape 8 : Valider le Déploiement**
```bash
# Suivre le déploiement
gh run watch

# Une fois terminé, tester :
curl -I https://lecircographe.fr          # → HTTP 503 (maintenance)
curl -I https://lecircographe.fr/up       # → HTTP 200 (healthcheck)

# Tester login admin dans le navigateur
# https://lecircographe.fr/sessions/new
```

---

## 📋 **Checklist Complète**

### **Avant de Commencer :**
- [ ] Sur PC fixe
- [ ] `git pull origin dev` effectué
- [ ] Documentation `knowledge/` présente
- [ ] Branche `feature/production-maintenance-mode` créée

### **Modifications Code :**
- [ ] Middleware maintenance modifié (admin bypass)
- [ ] Horaires affichés sur page maintenance
- [ ] Tests locaux avec `MAINTENANCE_MODE=true`
- [ ] Admin peut se connecter en mode maintenance
- [ ] Horaires modifiables par admin

### **Configuration GitHub :**
- [ ] `MAINTENANCE_MODE=true` configuré
- [ ] Secrets production vérifiés
- [ ] Workflow 05 prêt

### **Déploiement :**
- [ ] Code mergé vers `main`
- [ ] GitHub Actions déclenché
- [ ] Déploiement réussi
- [ ] Site accessible en HTTPS
- [ ] Page maintenance affichée
- [ ] Admin peut se connecter

---

## 🔄 **Désactiver Maintenance Plus Tard**

### **Méthode 1 : Via GitHub (Recommandé)**
```bash
gh variable set MAINTENANCE_MODE --body "false"
git commit --allow-empty -m "chore: Disable maintenance mode"
git push origin main
```

### **Méthode 2 : Via SSH VPS**
```bash
ssh deploy@$PRODUCTION_SERVER_IP
docker exec -it <container-id> bash
export MAINTENANCE_MODE=false
exit
docker restart <container-id>
```

---

## 📚 **Documentation Utile**

- **Plan complet :** `knowledge/PRODUCTION_DEPLOYMENT_PLAN.md`
- **Règles critiques :** `knowledge/KNOWLEDGE_BASE.md`
- **Guide déploiement :** `knowledge/DEPLOYMENT_GUIDE.md`
- **Optimisations :** `knowledge/OPTIMIZATIONS_TODO.md`

---

## 🎯 **Résumé Ultra-Rapide**

```bash
# Sur PC fixe
git checkout dev && git pull origin dev
git checkout -b feature/production-maintenance-mode

# Modifier app/middleware/maintenance_mode_middleware.rb
# (Voir PRODUCTION_DEPLOYMENT_PLAN.md pour le code exact)

# Tester
MAINTENANCE_MODE=true RAILS_ENV=production rails s

# Déployer
git add . && git commit -m "feat: Production maintenance mode"
git push origin feature/production-maintenance-mode
git checkout main && git merge feature/production-maintenance-mode
git push origin main

# Valider
gh run watch
```

---

**Bon courage chez toi ! 🚀**  
**Tout est documenté, tu ne peux pas te perdre !** 😊

