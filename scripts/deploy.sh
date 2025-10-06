#!/bin/bash

# Script de déploiement pour Le Circographe
# Usage: ./scripts/deploy.sh [staging|production]

set -e

ENVIRONMENT=${1:-staging}

echo "🚀 Déploiement de Le Circographe en $ENVIRONMENT"

# Vérifications préalables
if [ ! -f "config/master.key" ]; then
    echo "❌ Fichier config/master.key manquant"
    exit 1
fi

if [ ! -f ".kamal/secrets" ]; then
    echo "❌ Fichier .kamal/secrets manquant"
    exit 1
fi

# Configuration selon l'environnement
case $ENVIRONMENT in
    "staging")
        echo "📦 Déploiement en staging..."
        # Configuration staging
        export KAMAL_DESTINATION=staging
        ;;
    "production")
        echo "🏭 Déploiement en production..."
        # Configuration production
        export KAMAL_DESTINATION=production
        ;;
    *)
        echo "❌ Environnement invalide. Utilisez 'staging' ou 'production'"
        exit 1
        ;;
esac

# Build et déploiement avec Kamal
echo "🔨 Build de l'image Docker..."
kamal build

echo "🚢 Déploiement avec Kamal..."
kamal deploy

echo "✅ Déploiement terminé avec succès !"
echo "🌐 Application disponible sur: https://lecircographe.fr"
