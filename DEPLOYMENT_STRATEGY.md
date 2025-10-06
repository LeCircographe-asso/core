# 🚀 Stratégie de Déploiement - Le Circographe

## 📋 Organisation des repositories

### 🏗️ **core** (Repository principal)
**Contenu :** Code source de l'application Rails
- ✅ Code Rails (app/, config/, etc.)
- ✅ Documentation (docs/)
- ✅ Scripts de déploiement
- ✅ GitHub Actions workflows
- ❌ **JAMAIS** de secrets

### 🔧 **deployment** (Scripts et configs)
**Contenu :** Scripts de déploiement et maintenance
- ✅ Scripts Docker
- ✅ Configurations serveur
- ✅ Scripts de backup/restauration
- ❌ **JAMAIS** de secrets

### 🎨 **design** (Assets visuels)
**Contenu :** Assets UI/UX
- ✅ Maquettes
- ✅ Palette de couleurs
- ✅ Composants Flowbite

### ⚙️ **.github** (Configuration GitHub)
**Contenu :** Configuration organisation
- ✅ Templates de PR/Issues
- ✅ Workflows partagés
- ✅ Dependabot config

## 🔐 Gestion des secrets

### ✅ **PUBLIC** (peut être pushé)
- Code source
- Documentation
- Scripts (sans secrets)
- Configuration d'exemple (.env.example)

### ❌ **SECRET** (jamais pushé)
- Fichiers .env.local, .env.production, .env.staging
- .kamal/secrets
- config/master.key
- Certificats SSL
- Clés API réelles

## 🎯 Plan de déploiement

### Phase 1 : Préparation (maintenant)
1. **Push du code core** vers le repository `core`
2. **Configuration des secrets** sur GitHub
3. **Test local** de l'application

### Phase 2 : Staging
1. **Déploiement automatique** via GitHub Actions
2. **Tests sur staging.lecircographe.fr**
3. **Validation des fonctionnalités**

### Phase 3 : Production
1. **Déploiement manuel** après validation
2. **Monitoring** et maintenance

## 📦 Ce qui doit être pushé maintenant

### Dans **core** :
- ✅ Code Rails 8.0
- ✅ Documentation consolidée
- ✅ Scripts de déploiement
- ✅ GitHub Actions workflows
- ✅ Configuration d'exemple

### Dans **deployment** :
- ✅ Scripts de maintenance
- ✅ Configurations serveur
- ✅ Procédures de backup

## 🔗 Liaison entre repositories

### Via GitHub Actions
```yaml
# Dans core/.github/workflows/
# Utilise les scripts du repository deployment
```

### Via Dependabot
```yaml
# Dans .github/dependabot/
# Met à jour automatiquement les dépendances
```

## 🚨 Sécurité

### Secrets GitHub
- RAILS_MASTER_KEY
- KAMAL_REGISTRY_PASSWORD
- SMTP credentials
- Stripe keys

### Variables d'environnement
- Développement : .env.development
- Staging : .env.staging
- Production : .env.production

## 📋 Checklist avant push

### ✅ Vérifications
- [ ] Aucun secret dans le code
- [ ] .gitignore configuré
- [ ] Tests passent localement
- [ ] Documentation à jour
- [ ] Scripts fonctionnels

### 🔍 Commandes de vérification
```bash
# Vérifier les secrets
grep -r "password\|secret\|key" . --exclude="*.example" --exclude=".gitignore"

# Vérifier le .gitignore
git status

# Tester localement
rails test
```

## 🎯 Prochaines étapes

1. **Push vers core** (code + docs + scripts)
2. **Configurer les secrets** GitHub
3. **Tester le déploiement staging**
4. **Valider en production**

---

*Stratégie mise à jour en Octobre 2025*
