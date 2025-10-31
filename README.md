# 🎪 Le Circographe

<div align="center">
  <img src="docs/documentations/assets/screenshots/logo.png" alt="Logo Le Circographe" width="200"/>
  <p><i>Une application de gestion complète pour association de cirque</i></p>
  
  ![Version](https://img.shields.io/badge/version-1.3.0-blue)
  ![Rails](https://img.shields.io/badge/Rails-8.1.1-red)
  ![License](https://img.shields.io/badge/license-MIT-green)
  ![Tests](https://img.shields.io/badge/tests-10.42%25-yellow)
</div>

## 🎯 Vue d'ensemble

Le Circographe est une application de gestion complète pour une association de cirque, développée avec Ruby on Rails 8.1.1. Cette application couvre l'ensemble des aspects de gestion d'une association de cirque moderne.

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

**🚀 Déploiement automatique via GitHub Actions :**
- **Staging** : Push sur branche `staging` → Déploiement automatique
- **Production** : Push sur branche `main` → Déploiement automatique
- **Promotion** : Workflow "04 - Promote to Main" → staging → main

**🔧 Scripts utilitaires :**
```bash
# Mode maintenance
./scripts/maintenance.sh [enable|disable|status] [staging|production]

# Mise à jour serveur (urgence)
./scripts/server-pull.sh [staging|production] [SERVER_IP]
```

**🧪 Tests :**
```bash
# Lancer tous les tests avec couverture
bin/test

# Tests rapides (models + services)
bin/test_fast

# Mode watch pour TDD (requiert Guard)
bin/test_watch

# Sans couverture (plus rapide)
bin/test --no-coverage
```

## 🔧 Environnements

- **Development** : Local (localhost:3000)
- **Staging** : staging.lecircographe.fr
- **Production** : lecircographe.fr

## 📋 Prérequis

- Ruby 3.3.5+
- Rails 8.1.1+
- Docker (pour le déploiement)
- Kamal (pour le déploiement)

## 📚 Documentation

### 🧭 Navigation principale

- **[Documentation complète](docs/README.md)** - Guide complet du projet
- **[Configuration Rails 8.1](docs/documentations/technical/RAILS8_CONFIG.md)** - Nouvelles fonctionnalités
- **[Déploiement](docs/documentations/technical/deployment/)** - Guides de déploiement
- **[Environnements](docs/documentations/technical/ENVIRONMENTS.md)** - Configuration des environnements

### 🧪 Tests et Qualité

- **[Guide TDD](docs/TDD_WORKFLOW.md)** - Workflow Test-Driven Development
- **[Rapport d'Audit Tests](docs/TEST_AUDIT_REPORT.md)** - État de la couverture de code
- **[Approche TDD Réaliste](docs/TDD_REALISTIC_APPROACH.md)** - Stratégie avec logique métier incomplète
- **[Tests avec Logique Instable](docs/TEST_STRATEGY_UNSTABLE_LOGIC.md)** - ✅ **NOUVEAU** Comment tester quand logique bouge
- **[Classification Zones](docs/ZONES_CLASSIFICATION.md)** - Zone 1/2/3 pour tests
- **[Logique Métier](docs/BUSINESS_LOGIC.md)** - Domains et règles immutables
- **[Stratégie Backend](docs/BACKEND_STRATEGY.md)** - Organisation du développement

### 📁 Documentation détaillée

- **[📁 Domaines Métier](docs/documentations/domains/README.md)** - Règles et spécifications métier par domaine
- **[📁 Documentation Whimsical](https://whimsical.com/circograph-LAUT9hRLjkgEcGkLDKFPKV)** - Contient toute les documentations et graphiques
- **[📁 Wireframe](https://whimsical.com/wireframe-content-mapping-HYkmAuT9fc9BdZPB2vUvGc)** - Wireframe
- **[📁 Schema BDD](https://whimsical.com/diagram-database-J4Z17pjJ61YmVM9LK5jPMx)** - Schema BDD
- **[📁 User Stories](https://whimsical.com/user-stories-fonctionnal-mapping-GTkoaDv7mHwg8q8h3w5Mt4)** - User Stories
- **[📁 Guides Utilisateur](docs/documentations/guide/README.md)** - Guides pour les utilisateurs finaux

## 🔗 Liens utiles

- [Documentation technique](docs/documentations/technical/)
- [Guides utilisateur](docs/documentations/USER_GUIDES.md)
- [Guide administrateur](docs/documentations/ADMIN_GUIDE.md)
- [📝 Contribution](CONTRIBUTING.md)
- [🛠️ Guide de développement](CONTRIBUTING.md)

## 🎪 Fonctionnalités

- **Gestion des membres** - Adhésions et suivi
- **Événements** - Planning et organisation
- **Paiements** - Gestion des cotisations
- **Communication** - Newsletter et notifications
- **Administration** - Interface d'administration complète

---

*Application développée avec ❤️ pour Le Circographe*