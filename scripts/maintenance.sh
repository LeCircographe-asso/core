#!/bin/bash

# Script de gestion du mode maintenance pour Le Circographe
# Usage: ./scripts/maintenance.sh [enable|disable|status] [staging|production]

set -e

ACTION=${1:-status}
ENVIRONMENT=${2:-staging}

# Configuration selon l'environnement
case $ENVIRONMENT in
    "staging")
        CONFIG_FILE="config/deploy.staging.yml"
        ENV_NAME="staging"
        ;;
    "production")
        CONFIG_FILE="config/deploy.yml"
        ENV_NAME="production"
        ;;
    *)
        echo "❌ Environnement invalide. Utilisez 'staging' ou 'production'"
        exit 1
        ;;
esac

echo "🔧 Gestion du mode maintenance - $ENV_NAME"

case $ACTION in
    "enable")
        echo "🚧 Activation du mode maintenance..."
        
        # Méthode 1: Variable d'environnement
        echo "MAINTENANCE_MODE=true" | kamal app exec -i -c $CONFIG_FILE "cat > /tmp/maintenance"
        
        # Méthode 2: Redémarrage avec variable d'environnement
        kamal app exec -c $CONFIG_FILE "export MAINTENANCE_MODE=true"
        
        echo "✅ Mode maintenance activé pour $ENV_NAME"
        echo "🌐 Site accessible mais en mode maintenance"
        ;;
        
    "disable")
        echo "✅ Désactivation du mode maintenance..."
        
        # Supprimer le fichier de maintenance
        kamal app exec -c $CONFIG_FILE "rm -f /tmp/maintenance"
        
        # Redémarrer l'application
        kamal app restart -c $CONFIG_FILE
        
        echo "✅ Mode maintenance désactivé pour $ENV_NAME"
        echo "🌐 Site pleinement accessible"
        ;;
        
    "status")
        echo "📊 Statut du mode maintenance pour $ENV_NAME:"
        
        # Vérifier le fichier de maintenance
        if kamal app exec -c $CONFIG_FILE "test -f /tmp/maintenance" 2>/dev/null; then
            MAINTENANCE_FILE=$(kamal app exec -c $CONFIG_FILE "cat /tmp/maintenance 2>/dev/null || echo 'false'")
            echo "📁 Fichier maintenance: $MAINTENANCE_FILE"
        else
            echo "📁 Fichier maintenance: absent"
        fi
        
        # Vérifier la variable d'environnement
        MAINTENANCE_ENV=$(kamal app exec -c $CONFIG_FILE "echo \$MAINTENANCE_MODE" 2>/dev/null || echo "non définie")
        echo "🔧 Variable MAINTENANCE_MODE: $MAINTENANCE_ENV"
        
        # Tester l'accès au site
        if [ "$ENVIRONMENT" = "staging" ]; then
            URL="https://staging.lecircographe.fr"
        else
            URL="https://lecircographe.fr"
        fi
        
        echo "🌐 Test d'accès à $URL..."
        if curl -s -o /dev/null -w "%{http_code}" "$URL" | grep -q "503"; then
            echo "🚧 Site en mode maintenance (HTTP 503)"
        elif curl -s -o /dev/null -w "%{http_code}" "$URL" | grep -q "200"; then
            echo "✅ Site accessible normalement (HTTP 200)"
        else
            echo "❓ Statut inconnu"
        fi
        ;;
        
    *)
        echo "❌ Action invalide. Utilisez 'enable', 'disable' ou 'status'"
        echo ""
        echo "Usage: $0 [enable|disable|status] [staging|production]"
        echo ""
        echo "Exemples:"
        echo "  $0 enable staging     # Activer maintenance staging"
        echo "  $0 disable production # Désactiver maintenance production"
        echo "  $0 status staging     # Vérifier statut staging"
        exit 1
        ;;
esac
