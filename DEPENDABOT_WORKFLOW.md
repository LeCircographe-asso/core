# 🔄 Workflow Dependabot - Le Circographe

## 📋 Vue d'ensemble

Le workflow Dependabot est maintenant configuré pour tester automatiquement les mises à jour avant déploiement.

## 🔄 Flux complet

### 1. **Mises à jour Dependabot**
```
Dependabot détecte les mises à jour → Crée PR vers branche `deps`
```

### 2. **Tests automatiques**
```
PR vers `deps` → Tests automatiques → Validation des configurations
```

### 3. **Auto-merge vers dev**
```
Tests passent → Auto-merge vers `dev` → Déploiement staging automatique
```

### 4. **Validation staging**
```
Staging déployé → Tests manuels → Validation fonctionnelle
```

### 5. **Déploiement production**
```
Validation OK → Sync `dev` → `main` → Déploiement production
```

## 🎯 Branches et rôles

### 🌿 **`deps`** - Branche de test
- **Rôle** : Recevoir les PR Dependabot
- **Tests** : Validation automatique des mises à jour
- **Merge** : Auto-merge vers `dev` si tests OK

### 🌿 **`dev`** - Branche de développement
- **Rôle** : Développement principal
- **Déploiement** : Staging automatique
- **Tests** : Validation complète

### 🌿 **`main`** - Branche de production
- **Rôle** : Code de production stable
- **Déploiement** : Production (manuel)
- **Source** : Sync depuis `dev`

## 🧪 Tests Dependabot

### Tests automatiques sur `deps` :
- ✅ **Tests unitaires** : `bundle exec rspec`
- ✅ **Linting** : `rubocop` + `npm run lint`
- ✅ **Configuration** : Validation des fichiers de déploiement
- ✅ **Scripts** : Vérification de l'exécutabilité

### Critères d'auto-merge :
- ✅ Tous les tests passent
- ✅ Configuration de déploiement valide
- ✅ Scripts exécutables
- ✅ Pas de conflits

## 🚀 Déploiements

### Staging (automatique)
- **Déclencheur** : Push vers `dev`
- **URL** : `staging.lecircographe.fr`
- **Tests** : Validation fonctionnelle

### Production (manuel)
- **Déclencheur** : Sync `dev` → `main`
- **URL** : `lecircographe.fr`
- **Approbation** : Manuelle via GitHub Actions

## 📊 Monitoring

### Notifications
- ✅ **Tests Dependabot** : Résultats des tests
- ✅ **Auto-merge** : Confirmation de merge
- ✅ **Déploiement** : Statut staging/production

### Logs
- **Tests** : `.github/workflows/test-dependabot.yml`
- **Merge** : `.github/workflows/merge-dependabot.yml`
- **Sync** : `.github/workflows/sync-to-main.yml`

## 🔧 Configuration

### Dependabot (`.github/dependabot.yml`)
```yaml
version: 2
updates:
- package-ecosystem: bundler
  target-branch: "deps"
  schedule:
    interval: daily
- package-ecosystem: github-actions
  target-branch: "deps"
  schedule:
    interval: daily
```

### Workflows
- **`test-dependabot.yml`** : Tests sur branche `deps`
- **`merge-dependabot.yml`** : Auto-merge vers `dev`
- **`sync-to-main.yml`** : Sync `dev` → `main`
- **`ci.yml`** : CI/CD principal

## 🎉 Avantages

### ✅ **Sécurité**
- Tests automatiques avant merge
- Validation des configurations
- Pas de déploiement automatique en production

### ✅ **Efficacité**
- Auto-merge des mises à jour testées
- Déploiement staging automatique
- Validation manuelle pour production

### ✅ **Traçabilité**
- Logs complets des tests
- Historique des mises à jour
- Notifications de statut

## 🆘 Dépannage

### Problèmes courants
1. **Tests échouent** → Vérifier les logs, corriger les conflits
2. **Auto-merge bloqué** → Vérifier les critères, résoudre manuellement
3. **Déploiement échoue** → Vérifier les secrets, configuration serveur

### Commandes utiles
```bash
# Vérifier les tests
gh run list --workflow="Test Dependabot Updates"

# Voir les logs
gh run view [RUN_ID]

# Déclencher sync manuel
gh workflow run "Sync Dev to Main"
```

---

*Workflow configuré en Octobre 2025*
