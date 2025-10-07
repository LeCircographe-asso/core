#!/bin/bash

# Script de déploiement manuel pour Le Circographe
# Usage: ./scripts/deploy-manual.sh [staging|production]

set -e

ENVIRONMENT=${1:-production}
REGISTRY="ghcr.io/lecircographe-asso"
IMAGE_NAME="circographe"

echo "🚀 Déploiement manuel vers $ENVIRONMENT"
echo "=================================="

# Vérification des paramètres
if [[ "$ENVIRONMENT" != "staging" && "$ENVIRONMENT" != "production" ]]; then
    echo "❌ Erreur: Environnement doit être 'staging' ou 'production'"
    exit 1
fi

# Configuration selon l'environnement
if [[ "$ENVIRONMENT" == "staging" ]]; then
    CONFIG_FILE="config/deploy.staging.yml"
    TAG="staging"
else
    CONFIG_FILE="config/deploy.yml"
    TAG="production"
fi

echo "📋 Configuration:"
echo "  - Environnement: $ENVIRONMENT"
echo "  - Config: $CONFIG_FILE"
echo "  - Tag: $TAG"
echo ""

# Vérification des prérequis
echo "🔍 Vérification des prérequis..."

if ! command -v docker &> /dev/null; then
    echo "❌ Docker n'est pas installé"
    exit 1
fi

if ! command -v kamal &> /dev/null; then
    echo "❌ Kamal n'est pas installé. Installation..."
    gem install kamal
fi

# Build de l'image Docker
echo "🏗️  Build de l'image Docker..."
docker build -t $REGISTRY/$IMAGE_NAME:$TAG .

# Push vers le registry
echo "📤 Push vers le registry..."
docker push $REGISTRY/$IMAGE_NAME:$TAG

# Déploiement avec Kamal
echo "🚀 Déploiement avec Kamal..."
kamal deploy -c $CONFIG_FILE

echo ""
echo "✅ Déploiement terminé avec succès!"
echo "🌐 Site disponible sur: https://lecircographe.fr"
