# 🧪 Guide de Test - Mode Maintenance Local

**Date**: 2025-10-12  
**Objectif**: Tester le bypass admin du mode maintenance localement avant déploiement

---

## ✅ Modifications Appliquées

### **Middleware Amélioré** (`app/middleware/maintenance_mode_middleware.rb`)

**Nouvelle logique:**
```ruby
def call(env)
  request = Rack::Request.new(env)
  
  # 1. /up → Toujours autoriser (healthcheck Kamal)
  return @app.call(env) if healthcheck?(request)
  
  # 2. MAINTENANCE_MODE=false → Tout autoriser (staging)
  return @app.call(env) unless maintenance_enabled?
  
  # 3. Admin connecté OU page login → Autoriser
  return @app.call(env) if admin_access?(env, request)
  
  # 4. Visiteurs → Page maintenance
  maintenance_response
end
```

**Méthode `admin_access?`:**
- ✅ Autorise `/sessions/new` et `/sessions` (page login)
- ✅ Autorise `/admin/*` si `user_id` présent dans session
- ❌ Bloque tout le reste (visiteurs)

---

## 🧪 Tests à Effectuer

### **Container démarré avec:**
```bash
MAINTENANCE_MODE=true
RAILS_ENV=production
PORT=80 (exposé sur localhost:3000)
```

### **Test 1: Visiteur Normal** ❌
```bash
# Dans le navigateur
http://localhost:3000

# Attendu:
- Page maintenance affichée
- Statut HTTP: 503
- Logo Le Circographe visible
- Liens réseaux sociaux présents
```

### **Test 2: Healthcheck Kamal** ✅
```bash
curl -I http://localhost:3000/up

# Attendu:
HTTP/1.1 200 OK
```

### **Test 3: Page Login Accessible** ✅
```bash
# Dans le navigateur
http://localhost:3000/sessions/new

# Attendu:
- Formulaire de connexion Rails
- PAS la page maintenance
- Statut HTTP: 200
```

### **Test 4: Admin Dashboard (Après Login)** ✅
```bash
# Dans le navigateur
1. Aller sur http://localhost:3000/sessions/new
2. Se connecter avec compte admin (créé via seeds)
3. Aller sur http://localhost:3000/admin

# Attendu:
- Dashboard admin accessible
- PAS la page maintenance
- Toutes les fonctions admin disponibles
```

---

## 📊 Résultats Attendus

| Route | Visiteur | Admin Connecté | Statut |
|-------|----------|----------------|--------|
| `/` | Page maintenance (503) | Page maintenance (503) | ⚠️ Normal |
| `/up` | Healthcheck (200) | Healthcheck (200) | ✅ |
| `/sessions/new` | Formulaire login (200) | Formulaire login (200) | ✅ |
| `/sessions` (POST) | Login possible | Login possible | ✅ |
| `/admin/*` | Page maintenance (503) | Dashboard admin (200) | ✅ |

---

## 🐛 Problèmes Possibles

### **Si login ne fonctionne pas:**
- Vérifier que la base de données est initialisée
- Créer un admin via: `RAILS_ENV=production rails db:seed`
- Credentials admin (depuis seeds.rb):
  - Email: `admin@lecircographe.fr` (vérifier dans seeds.rb)
  - Password: `password` (ou celui défini dans seeds.rb)

### **Si session n'est pas chargée:**
- Vérifier `Rails.application.config.session_options`
- Vérifier que `SECRET_KEY_BASE` est défini
- Check logs: `docker logs <container_id>`

### **Si page maintenance s'affiche toujours:**
- Vérifier que `admin_access?` retourne `true`
- Ajouter des logs de debug dans le middleware
- Vérifier que `session["user_id"]` existe après login

---

## 🔄 Itérations Suivantes

Une fois le bypass admin validé:
1. ✅ Ajouter affichage des horaires sur page maintenance
2. ✅ Tester à nouveau localement
3. ✅ Déployer en production
4. ✅ Activer `MAINTENANCE_MODE=true` en production

---

## 📝 Notes

- **Staging**: `MAINTENANCE_MODE` non défini → Site normal
- **Production**: `MAINTENANCE_MODE=true` → Maintenance + admin bypass
- **Local**: Test avec Docker avant déploiement = Zéro risque!

