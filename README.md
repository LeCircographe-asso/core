# 🎪 Le Circographe

Application de gestion pour association de cirque développée avec Rails 8.0.

## 🚀 Démarrage rapide

### Développement local
```bash
# Installation
bundle install
rails db:reset
rails s

# Accès
http://localhost:3000
```

### Déploiement
```bash
# Staging
./scripts/deploy-staging.sh

# Production  
./scripts/deploy-production.sh
```

## 📚 Documentation

- **[Documentation complète](docs/README.md)** - Guide complet du projet
- **[Configuration Rails 8.0](docs/documentations/technical/RAILS8_CONFIG.md)** - Nouvelles fonctionnalités
- **[Déploiement](docs/documentations/technical/deployment/)** - Guides de déploiement
- **[Environnements](docs/documentations/technical/ENVIRONMENTS.md)** - Configuration des environnements

## 🔧 Environnements

- **Development** : Local (localhost:3000)
- **Staging** : staging.lecircographe.fr
- **Production** : lecircographe.fr

## 📋 Prérequis

- Ruby 3.2.5+
- Rails 8.0.2+
- Docker (pour le déploiement)
- Kamal (pour le déploiement)

## 🔗 Liens utiles

- [Documentation technique](docs/documentations/technical/)
- [Guides utilisateur](docs/documentations/USER_GUIDES.md)
- [Guide administrateur](docs/documentations/ADMIN_GUIDE.md)

---

*Application développée avec ❤️ pour Le Circographe*