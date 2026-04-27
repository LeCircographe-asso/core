# 🚀 Plan de Déploiement Production - Mode Maintenance

**Statut actuel:** ⚠️ Historique (snapshot 2025-10-12).  
**Source de vérité :** [`../operations/deployment.md`](../operations/deployment.md).

---

**Date :** 2025-10-12  
**Objectif :** Déployer en production avec mode maintenance activé + accès admin pour gérer les horaires

---

## 🎯 **Besoin Spécifique**

### **Contexte :**
- Site non terminé → Mode maintenance par défaut
- Admin doit pouvoir se connecter → Modifier les horaires
- Visiteurs voient → Page maintenance avec horaires affichés
- Flexibilité → Activer/désactiver maintenance facilement

### **Cas d'Usage :**
1. **Visiteur lambda** → Page maintenance (503)
2. **Admin connecté** → Accès dashboard + modification horaires
3. **Healthcheck Kamal** → `/up` toujours accessible (200)

---

## 🔧 **Solution Technique**

### **Architecture Proposée :**

```
Requête HTTP
    ↓
MaintenanceModeMiddleware
    ↓
    ├─ /up → ✅ Passer (healthcheck)
    ├─ /admin/* + session admin → ✅ Passer (admin connecté)
    ├─ /sessions/new → ✅ Passer (page login)
    └─ Autre → ❌ Page maintenance (503)
```

### **Modifications Nécessaires :**

#### **1. Améliorer le Middleware Maintenance**

**Fichier :** `app/middleware/maintenance_mode_middleware.rb`

**Ajouts :**
- Exclure `/admin/*` si admin connecté
- Exclure `/sessions/new` (page login)
- Afficher les horaires sur la page maintenance

#### **2. Configuration ENV Variables**

**Variables requises :**
```bash
# Production
MAINTENANCE_MODE=true           # Activer maintenance
RAILS_ENV=production
SECRET_KEY_BASE=<secret>
RAILS_MASTER_KEY=<master_key>

# Optionnel (pour page maintenance)
GOOGLE_PAGE_URL=<url>
INSTAGRAM_URL=<url>
WHATSAPP_COMMUNITY_URL=<url>
FACEBOOK_URL=<url>
```

#### **3. Gestion des Horaires en Maintenance**

**Option A :** Afficher horaires statiques sur page maintenance
**Option B :** API publique `/api/opening_hours` (sans auth)
**Option C :** Intégrer horaires directement dans HTML maintenance

---

## 📋 **Implémentation Détaillée**

### **Étape 1 : Modifier le Middleware**

```ruby
# app/middleware/maintenance_mode_middleware.rb
class MaintenanceModeMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)
    
    # Toujours autoriser healthcheck
    return @app.call(env) if healthcheck?(request)
    
    # Si maintenance désactivée, passer
    return @app.call(env) unless maintenance_enabled?
    
    # Autoriser admin connecté
    return @app.call(env) if admin_access?(env, request)
    
    # Sinon, page maintenance
    maintenance_response
  end

  private

  def maintenance_enabled?
    ENV["MAINTENANCE_MODE"].to_s.strip.casecmp("true").zero?
  end

  def healthcheck?(request)
    request.path == "/up"
  end

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
    # Charger la session Rails
    session_key = Rails.application.config.session_options[:key] || "_circographe_session"
    cookie_jar = ActionDispatch::Cookies::CookieJar.build(
      Rack::Request.new(env),
      {}
    )
    
    # Décoder la session
    session_data = cookie_jar.encrypted[session_key]
    session_data.is_a?(Hash) ? session_data : {}
  rescue StandardError
    {}
  end

  def maintenance_response
    # ... (code HTML existant avec ajout des horaires)
  end
end
```

### **Étape 2 : Afficher Horaires sur Page Maintenance**

**Option Simple :** Ajouter une section horaires dans le HTML

```ruby
def maintenance_response
  opening_hours_html = render_opening_hours
  
  body = <<~HTML
    <!DOCTYPE html>
    <html lang="fr">
      <!-- ... head existant ... -->
      <body>
        <div class="card">
          <!-- ... contenu existant ... -->
          
          #{opening_hours_html}
          
          <!-- ... réseaux sociaux ... -->
        </div>
      </body>
    </html>
  HTML
  
  [ 503, headers, [ body ] ]
end

def render_opening_hours
  hours = fetch_opening_hours
  
  <<~HTML
    <div style="margin: 24px 0; padding: 20px; background: #f8fafc; border-radius: 12px; text-align: left;">
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

def fetch_opening_hours
  # Lire depuis cache Rails (même source que admin)
  Rails.cache.fetch("opening_hours") || default_opening_hours
rescue StandardError
  default_opening_hours
end

def default_opening_hours
  {
    "lundi" => "Fermé",
    "mardi" => "14:00 - 18:00",
    "mercredi" => "14:00 - 18:00",
    "jeudi" => "14:00 - 18:00",
    "vendredi" => "14:00 - 18:00",
    "samedi" => "10:00 - 18:00",
    "dimanche" => "Fermé"
  }
end
```

---

## 🚀 **Déploiement Production**

### **Workflow Complet :**

```bash
# 1. Créer branche production
git checkout -b deploy/production-with-maintenance

# 2. Appliquer les modifications middleware
# (voir code ci-dessus)

# 3. Tester localement
MAINTENANCE_MODE=true RAILS_ENV=production rails s

# 4. Commit et push
git add .
git commit -m "feat: Add admin bypass for maintenance mode"
git push origin deploy/production-with-maintenance

# 5. Merger vers main (ou production)
git checkout main
git merge deploy/production-with-maintenance
git push origin main

# 6. Configurer GitHub Secrets Production
# MAINTENANCE_MODE=true (dans GitHub Variables)

# 7. Déclencher déploiement production
# → GitHub Actions workflow 05 se déclenche
```

### **Configuration Kamal Production :**

**Fichier :** `config/deploy.production.yml`

```yaml
env:
  clear:
    RAILS_ENV: production
  secret:
    - RAILS_MASTER_KEY
    - SECRET_KEY_BASE
    - MAINTENANCE_MODE  # ← Ajouter cette variable
```

**Fichier :** `.kamal/secrets` (production)

```bash
# .kamal/secrets
RAILS_MASTER_KEY=$(gh secret get RAILS_MASTER_KEY)
SECRET_KEY_BASE=$(gh secret get SECRET_KEY_BASE)
MAINTENANCE_MODE=true  # ← Mode maintenance activé par défaut
```

---

## 🔄 **Activer/Désactiver Maintenance**

### **Méthode 1 : Via GitHub Variables (Recommandé)**

```bash
# Activer maintenance
gh variable set MAINTENANCE_MODE --body "true" --repo lecircographe-asso/circographe

# Désactiver maintenance
gh variable set MAINTENANCE_MODE --body "false" --repo lecircographe-asso/circographe

# Redéployer pour appliquer
git commit --allow-empty -m "chore: Toggle maintenance mode"
git push origin main
```

### **Méthode 2 : Via SSH sur VPS (Immédiat)**

```bash
# Se connecter au VPS
ssh deploy@$PRODUCTION_SERVER_IP

# Modifier la variable dans le conteneur
docker exec -it <container-id> bash
export MAINTENANCE_MODE=false

# Redémarrer le conteneur
exit
docker restart <container-id>
```

### **Méthode 3 : Via Dashboard Admin (Future Feature)**

**Créer un controller admin :**

```ruby
# app/controllers/admin/maintenance_controller.rb
module Admin
  class MaintenanceController < BaseController
    before_action :require_super_admin

    def toggle
      current_state = ENV["MAINTENANCE_MODE"] == "true"
      new_state = !current_state
      
      # Écrire dans fichier pour persistance
      File.write("/tmp/maintenance", new_state.to_s)
      
      flash[:success] = "Mode maintenance #{new_state ? 'activé' : 'désactivé'}"
      redirect_to admin_dashboard_path
    end

    private

    def require_super_admin
      unless Current.user&.system_role == "super_admin"
        redirect_to root_path, alert: "Accès refusé"
      end
    end
  end
end
```

---

## ✅ **Checklist Déploiement Production**

### **Avant Déploiement :**
- [ ] Middleware maintenance modifié (admin bypass)
- [ ] Horaires affichés sur page maintenance
- [ ] Tests locaux avec `MAINTENANCE_MODE=true`
- [ ] Admin peut se connecter en mode maintenance
- [ ] Horaires modifiables par admin
- [ ] `/up` toujours accessible (healthcheck)

### **Configuration GitHub :**
- [ ] `MAINTENANCE_MODE=true` dans Variables
- [ ] `RAILS_MASTER_KEY` dans Secrets
- [ ] `SECRET_KEY_BASE` dans Secrets
- [ ] `SSH_PRIVATE_KEY` dans Secrets
- [ ] `PRODUCTION_SERVER_IP` dans Variables

### **Déploiement :**
- [ ] Branche dédiée créée
- [ ] Code mergé vers `main`
- [ ] GitHub Actions workflow déclenché
- [ ] Déploiement réussi (vérifier logs)
- [ ] Site accessible en HTTPS
- [ ] Page maintenance affichée
- [ ] Admin peut se connecter
- [ ] Horaires modifiables

### **Post-Déploiement :**
- [ ] Tester `/up` → HTTP 200
- [ ] Tester `https://lecircographe.fr` → Page maintenance (503)
- [ ] Tester login admin → Dashboard accessible
- [ ] Tester modification horaires → Sauvegarde OK
- [ ] Vérifier horaires sur page maintenance → Mis à jour

---

## 🎯 **Résumé**

### **Ce qui sera déployé :**
1. ✅ Site en mode maintenance par défaut
2. ✅ Page maintenance avec horaires dynamiques
3. ✅ Admin peut se connecter et modifier horaires
4. ✅ Healthcheck Kamal fonctionne
5. ✅ Tous les fix CSS/assets appliqués

### **Comment gérer :**
- **Activer maintenance** : `MAINTENANCE_MODE=true`
- **Désactiver maintenance** : `MAINTENANCE_MODE=false`
- **Modifier horaires** : Login admin → Dashboard → Horaires

### **Avantages :**
- 🔒 Site protégé pendant développement
- 📅 Horaires visibles pour visiteurs
- 🛠️ Admin peut travailler normalement
- 🚀 Désactivation simple quand prêt

---

**Prêt à implémenter ?** Je peux commencer par modifier le middleware si tu valides cette approche ! 🚀
