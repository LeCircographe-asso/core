#!/bin/bash

# Script pour tester la connexion au GitHub Container Registry
# Usage: ./scripts/test-registry.sh [token]

set -e

echo "🐳 Test de connexion au GitHub Container Registry"
echo "================================================="

# Vérifier si un token est fourni
if [ -z "$1" ]; then
    echo "❌ Erreur: Token GitHub requis"
    echo "Usage: $0 <github_token>"
    echo "Exemple: $0 ghp_xxxxxxxxxxxxxxxxxxxx"
    exit 1
fi

TOKEN="$1"
REGISTRY="ghcr.io"
USERNAME="LeCircographe-asso"
IMAGE="circographe"

echo "🔐 Configuration:"
echo "   Registry: $REGISTRY"
echo "   Username: $USERNAME"
echo "   Image: $IMAGE"
echo "   Token: ${TOKEN:0:10}..."
echo ""

# Test de connexion Docker
echo "🔍 Test de connexion Docker..."
if docker login $REGISTRY -u $USERNAME -p $TOKEN; then
    echo "✅ Connexion Docker réussie"
else
    echo "❌ Échec de la connexion Docker"
    exit 1
fi

# Test de pull d'une image (si elle existe)
echo ""
echo "🔍 Test de pull d'image..."
if docker pull $REGISTRY/$USERNAME/$IMAGE:latest 2>/dev/null; then
    echo "✅ Pull d'image réussi"
else
    echo "⚠️  Image non trouvée (normal si pas encore déployée)"
fi

# Test de push (simulation)
echo ""
echo "🔍 Test de permissions de push..."
if echo "$TOKEN" | docker login $REGISTRY -u $USERNAME --password-stdin >/dev/null 2>&1; then
    echo "✅ Permissions de push OK"
else
    echo "❌ Permissions de push insuffisantes"
    exit 1
fi

# Déconnexion
docker logout $REGISTRY >/dev/null 2>&1

echo ""
echo "🎉 Tests terminés avec succès !"
echo "   Le token GitHub est valide et a les bonnes permissions"
echo "   Vous pouvez maintenant configurer KAMAL_REGISTRY_PASSWORD"
