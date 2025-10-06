#!/bin/bash

# Script de déploiement staging - Le Circographe
# Utilise Rails 8.0 avec Kamal

set -e

echo "🚀 Déploiement Staging - Le Circographe"
echo "======================================"

# Vérifier que Kamal est installé
if ! command -v kamal &> /dev/null; then
    echo "❌ Kamal n'est pas installé. Installez-le avec: gem install kamal"
    exit 1
fi

# Vérifier que les secrets sont configurés
if [ ! -f .kamal/secrets ]; then
    echo "❌ Fichier .kamal/secrets manquant"
    echo "💡 Copiez .kamal/secrets.example vers .kamal/secrets et configurez vos valeurs"
    exit 1
fi

# Vérifier que l'environnement staging est configuré
if [ ! -f .env.staging ]; then
    echo "❌ Fichier .env.staging manquant"
    echo "💡 Copiez config/staging.env.example vers .env.staging et configurez vos valeurs"
    exit 1
fi

echo "📋 Préparation du déploiement staging..."

# Créer les bases de données staging si elles n'existent pas
echo "🗄️  Vérification des bases de données staging..."
RAILS_ENV=staging bundle exec rails db:create 2>/dev/null || echo "Bases déjà créées"

# Exécuter les migrations
echo "🔄 Exécution des migrations staging..."
RAILS_ENV=staging bundle exec rails db:migrate

# Nettoyer et précompiler les assets
echo "📦 Nettoyage et précompilation des assets..."
bundle exec rails assets:clobber
bundle exec rails assets:precompile

# Construire l'image Docker
echo "🐳 Construction de l'image Docker staging..."
kamal build -c config/deploy.staging.yml

# Déployer avec Kamal
echo "🚀 Déploiement avec Kamal..."
kamal deploy -c config/deploy.staging.yml

echo ""
echo "✅ Déploiement staging terminé !"
echo "🌐 URL: https://staging.lecircographe.fr"
echo "📊 Logs: kamal logs -c config/deploy.staging.yml"
echo "🔧 Console: kamal app exec -i -c config/deploy.staging.yml 'bin/rails console'"
