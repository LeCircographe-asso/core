#!/bin/bash

# Script de réparation rapide du serveur après redémarrage
# Usage: ./scripts/fix_server.sh

set -e

SERVER_IP="87.106.173.45"

echo "🔧 Réparation du serveur Le Circographe"
echo "📍 Serveur: $SERVER_IP"

# Vérifier la connexion SSH
echo "🔍 Test de connexion SSH..."
if ! ssh -o ConnectTimeout=10 root@$SERVER_IP "echo 'Connexion SSH OK'"; then
    echo "❌ Impossible de se connecter au serveur"
    echo "Vérifiez votre clé SSH et l'accès au serveur"
    exit 1
fi

echo "✅ Connexion SSH OK"

# Installer Docker sur le serveur
echo "🐳 Installation de Docker..."
ssh root@$SERVER_IP << 'EOF'
    # Mise à jour du système
    apt update && apt upgrade -y
    
    # Installation Docker
    if ! command -v docker &> /dev/null; then
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        rm get-docker.sh
    fi
    
    # Vérification
    docker --version
    
    # Configuration firewall
    ufw allow 22
    ufw allow 80
    ufw allow 443
    ufw --force enable
    
    echo "✅ Docker installé et firewall configuré"
EOF

# Vérifier la configuration Kamal
echo "🔍 Vérification de la configuration Kamal..."
if [ ! -f ".kamal/secrets" ]; then
    echo "❌ Fichier .kamal/secrets manquant"
    echo "Copiez .kamal/secrets.example vers .kamal/secrets et configurez vos secrets"
    exit 1
fi

# Test de la configuration
echo "🧪 Test de la configuration Kamal..."
kamal config -c config/deploy.staging.yml

echo "✅ Configuration Kamal OK"

# Déploiement staging
echo "🚀 Déploiement staging..."
./scripts/deploy.sh staging

echo "🎉 Serveur réparé et déployé !"
echo "🌐 Staging: https://staging.lecircographe.fr"
echo "🌐 Production: https://lecircographe.fr"
