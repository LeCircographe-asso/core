#!/bin/bash
# Script de configuration des environnements - Le Circographe
# Usage: ./scripts/setup-environment.sh [development|staging|production]

set -e

ENVIRONMENT=${1:-development}

echo "🔧 Configuration de l'environnement: $ENVIRONMENT"

case $ENVIRONMENT in
  "development")
    echo "📁 Configuration du développement local..."
    
    # Créer les dossiers nécessaires
    mkdir -p storage
    mkdir -p log
    mkdir -p tmp
    
    # Copier les fichiers d'exemple
    if [ ! -f .env ]; then
      cp config/secrets/env.development.example .env
      echo "✅ Fichier .env créé depuis env.development.example"
      echo "⚠️  N'oubliez pas de remplir les vraies valeurs dans .env"
    fi
    
    # Installer les dépendances
    bundle install
    npm install
    
    # Préparer la base de données
    bundle exec rails db:create
    bundle exec rails db:migrate
    
    echo "✅ Environnement development configuré"
    echo "🚀 Lancez avec: ./bin/dev"
    ;;
    
  "staging")
    echo "🏗️  Configuration pour le déploiement staging..."
    
    # Vérifier les variables d'environnement nécessaires
    if [ -z "$RAILS_MASTER_KEY" ]; then
      echo "❌ RAILS_MASTER_KEY manquante pour staging"
      echo "💡 Définissez-la via: export RAILS_MASTER_KEY=your_staging_key"
      exit 1
    fi
    
    if [ -z "$KAMAL_REGISTRY_PASSWORD" ]; then
      echo "❌ KAMAL_REGISTRY_PASSWORD manquante"
      echo "💡 Définissez votre GitHub token pour le registry"
      exit 1
    fi
    
    echo "✅ Variables d'environnement staging vérifiées"
    echo "🚀 Déployez avec: kamal deploy -c config/deploy.staging.yml"
    ;;
    
  "production")
    echo "🚀 Configuration pour le déploiement production..."
    
    # Vérifier les variables d'environnement nécessaires
    if [ -z "$RAILS_MASTER_KEY" ]; then
      echo "❌ RAILS_MASTER_KEY manquante pour production"
      echo "💡 Définissez-la via: export RAILS_MASTER_KEY=your_production_key"
      exit 1
    fi
    
    if [ -z "$KAMAL_REGISTRY_PASSWORD" ]; then
      echo "❌ KAMAL_REGISTRY_PASSWORD manquante"
      echo "💡 Définissez votre GitHub token pour le registry"
      exit 1
    fi
    
    if [ -z "$PRODUCTION_SERVER_IP" ]; then
      echo "❌ PRODUCTION_SERVER_IP manquante"
      echo "💡 Définissez l'IP de votre serveur production"
      exit 1
    fi
    
    echo "✅ Variables d'environnement production vérifiées"
    echo "🚀 Déployez avec: kamal deploy -c config/deploy.production.yml"
    ;;
    
  *)
    echo "❌ Environnement non reconnu: $ENVIRONMENT"
    echo "💡 Usage: $0 [development|staging|production]"
    exit 1
    ;;
esac

echo ""
echo "📚 Documentation: docs/ARCHITECTURE_ENVIRONNEMENTS.md"
echo "🔐 Secrets: config/secrets/env.$ENVIRONMENT.example"
