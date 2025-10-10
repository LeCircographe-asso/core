#!/bin/bash

# Script pour pull l'image sur le serveur
# Usage: ./scripts/server-pull.sh [staging|production]
# Note: Nécessite PRODUCTION_SERVER_IP ou STAGING_SERVER_IP en variable d'environnement

set -e

ENVIRONMENT=${1:-production}
REGISTRY="ghcr.io/lecircographe-asso"
IMAGE_NAME="circographe"

# Détermine l'IP du serveur selon l'environnement
if [[ "$ENVIRONMENT" == "staging" ]]; then
    SERVER_IP=${STAGING_SERVER_IP}
else
    SERVER_IP=${PRODUCTION_SERVER_IP}
fi

# Vérifie que l'IP est définie
if [[ -z "$SERVER_IP" ]]; then
    echo "❌ Erreur: Variable d'environnement non définie"
    echo "   Pour staging: définir STAGING_SERVER_IP"
    echo "   Pour production: définir PRODUCTION_SERVER_IP"
    exit 1
fi

echo "🖥️  Pull d'image sur le serveur"
echo "==============================="

# Configuration selon l'environnement
if [[ "$ENVIRONMENT" == "staging" ]]; then
    TAG="staging"
    CONFIG_FILE="config/deploy.staging.yml"
else
    TAG="production"
    CONFIG_FILE="config/deploy.yml"
fi

echo "📋 Configuration:"
echo "  - Serveur: $SERVER_IP"
echo "  - Environnement: $ENVIRONMENT"
echo "  - Image: $REGISTRY/$IMAGE_NAME:$TAG"
echo ""

# Connexion SSH et pull de l'image
echo "🔐 Connexion au serveur..."
ssh root@$SERVER_IP << EOF
    echo "📥 Pull de l'image Docker..."
    docker pull $REGISTRY/$IMAGE_NAME:$TAG
    
    echo "🔄 Redémarrage du service..."
    docker-compose down
    docker-compose up -d
    
    echo "🧹 Nettoyage des images inutilisées..."
    docker image prune -f
    
    echo "✅ Mise à jour terminée!"
EOF

echo ""
echo "🎉 Image mise à jour sur le serveur!"
echo "🌐 Site disponible sur: https://lecircographe.fr"
