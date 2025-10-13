#!/bin/bash
# Script pour tester Docker + Rails en mode production LOCALEMENT
# Usage: ./scripts/test-docker-production-local.sh

set -e

echo "🐳 === TEST DOCKER PRODUCTION LOCAL ==="
echo ""

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 1. Build l'image Docker (comme en prod)
echo -e "${YELLOW}📦 Step 1: Build de l'image Docker...${NC}"
docker build -t circographe-prod-test .

# 2. Arrêter les containers existants
echo -e "${YELLOW}🛑 Step 2: Nettoyage des containers existants...${NC}"
docker stop circographe-prod-test 2>/dev/null || true
docker rm circographe-prod-test 2>/dev/null || true

# 3. Lancer le container en mode production
echo -e "${YELLOW}🚀 Step 3: Lancement du container en PRODUCTION...${NC}"
docker run -d \
  --name circographe-prod-test \
  -p 3002:3000 \
  -e RAILS_ENV=production \
  -e MAINTENANCE_MODE=false \
  -e RAILS_MASTER_KEY=$(cat config/master.key) \
  -e SECRET_KEY_BASE=$(cat config/master.key) \
  -e RAILS_SERVE_STATIC_FILES=true \
  -e RAILS_LOG_TO_STDOUT=true \
  circographe-prod-test

# 4. Attendre que le serveur démarre
echo -e "${YELLOW}⏳ Step 4: Attente du démarrage (15s)...${NC}"
sleep 15

# 5. Vérifier les logs
echo -e "${YELLOW}📋 Step 5: Logs du container:${NC}"
docker logs circographe-prod-test --tail 30

# 6. Tester l'accès
echo ""
echo -e "${YELLOW}🧪 Step 6: Tests d'accès:${NC}"
echo ""

# Test healthcheck
echo -e "${GREEN}→ Test healthcheck:${NC}"
curl -s http://localhost:3002/up | head -5
echo ""

# Test page d'accueil
echo -e "${GREEN}→ Test page d'accueil:${NC}"
curl -s -I http://localhost:3002/ | head -10
echo ""

# 7. Instructions
echo ""
echo -e "${GREEN}✅ Container lancé avec succès!${NC}"
echo ""
echo "📍 Accès local: http://localhost:3002"
echo ""
echo "🔧 Commandes utiles:"
echo "  - Voir les logs:        docker logs -f circographe-prod-test"
echo "  - Entrer dans le container: docker exec -it circographe-prod-test /bin/bash"
echo "  - Arrêter:              docker stop circographe-prod-test"
echo "  - Supprimer:            docker rm circographe-prod-test"
echo ""
echo "🧪 Test avec maintenance:"
echo "  docker stop circographe-prod-test"
echo "  docker run -d --name circographe-prod-test -p 3002:3000 -e RAILS_ENV=production -e MAINTENANCE_MODE=true -e RAILS_MASTER_KEY=\$(cat config/master.key) -e SECRET_KEY_BASE=\$(cat config/master.key) -e RAILS_SERVE_STATIC_FILES=true circographe-prod-test"
echo ""

