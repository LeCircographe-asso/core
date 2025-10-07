#!/bin/bash

# Script pour pull l'image sur le serveur
# Usage: ./scripts/server-pull.sh [staging|production] [SERVER_IP]

set -e

ENVIRONMENT=${1:-production}
SERVER_IP=${2:-"82.165.63.129"}
REGISTRY="ghcr.io/lecircographe-asso"
IMAGE_NAME="circographe"

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
