# 🚀 Guide de Déploiement Manuel

## Vue d'ensemble

Le déploiement est maintenant **100% manuel** pour un contrôle total. Les workflows GitHub Actions sont désactivés et ne se déclenchent que manuellement.

## 📋 Prérequis

- Docker installé localement
- Kamal installé (`gem install kamal`)
- Accès SSH au serveur de production
- Secrets GitHub configurés

## 🎯 Workflow de Déploiement

### Option 1 : Déploiement Complet (Local)

```bash
# Build + Push + Deploy en une commande
./scripts/deploy-manual.sh production
```

### Option 2 : Pull d'Image sur Serveur

```bash
# Si l'image est déjà construite
./scripts/server-pull.sh production
```

## 🔧 Workflows GitHub Actions (Manuels)

### Tests
- **Fichier**: `.github/workflows/manual-test.yml`
- **Déclenchement**: Actions → Manual Testing → Run workflow
- **Usage**: Tester avant déploiement

### Build d'Image
- **Fichier**: `.github/workflows/build-image.yml`
- **Déclenchement**: Actions → Build Docker Image → Run workflow
- **Usage**: Construire l'image sans déployer

## 📊 Environnements

| Environnement | Serveur | Config | Tag |
|---------------|---------|---------|-----|
| **Staging** | 87.106.173.45 | `deploy.staging.yml` | `staging` |
| **Production** | 82.165.63.129 | `deploy.yml` | `production` |

## 🔐 Secrets Requis

Les secrets GitHub doivent être configurés :
- `RAILS_MASTER_KEY`
- `KAMAL_REGISTRY_PASSWORD`
- `STAGING_SERVER_IP`
- `PRODUCTION_SERVER_IP`

## 🎪 Déploiement de Production

1. **Tests** → Déclencher "Manual Testing"
2. **Build** → Déclencher "Build Docker Image"
3. **Deploy** → `./scripts/deploy-manual.sh production`

## 🛠️ Maintenance

- **Logs**: `kamal app logs -c config/deploy.yml`
- **Status**: `kamal app details -c config/deploy.yml`
- **Restart**: `kamal app restart -c config/deploy.yml`