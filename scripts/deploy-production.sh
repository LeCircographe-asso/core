#!/bin/bash

# Script de déploiement production - Le Circographe
# Utilise Rails 8.0 avec Kamal

set -e

echo "🏭 Déploiement Production - Le Circographe"
echo "========================================"

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

# Vérifier que l'environnement production est configuré
if [ ! -f .env.production ]; then
    echo "❌ Fichier .env.production manquant"
    echo "💡 Copiez config/production.env.example vers .env.production et configurez vos valeurs"
    exit 1
fi

echo "📋 Préparation du déploiement production..."

# Créer les bases de données production si elles n'existent pas
echo "🗄️  Vérification des bases de données production..."
RAILS_ENV=production bundle exec rails db:create 2>/dev/null || echo "Bases déjà créées"

# Exécuter les migrations
echo "🔄 Exécution des migrations production..."
RAILS_ENV=production bundle exec rails db:migrate

# Nettoyer et précompiler les assets
echo "📦 Nettoyage et précompilation des assets..."
bundle exec rails assets:clobber
bundle exec rails assets:precompile

# Construire l'image Docker
echo "🐳 Construction de l'image Docker production..."
kamal build

# Déployer avec Kamal
echo "🚀 Déploiement avec Kamal..."
kamal deploy

echo ""
echo "✅ Déploiement production terminé !"
echo "🌐 URL: https://lecircographe.fr"
echo "📊 Logs: kamal logs"
echo "🔧 Console: kamal app exec -i 'bin/rails console'"
