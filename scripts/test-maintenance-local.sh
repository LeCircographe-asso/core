#!/bin/bash
# Script de test du mode maintenance en local avec Docker
# Usage: ./scripts/test-maintenance-local.sh

set -e

echo "🐳 Building Docker image for maintenance test..."
docker build -t circographe-maintenance-test .

echo ""
echo "🚀 Starting container with MAINTENANCE_MODE=true..."
echo "📍 App will be available at: http://localhost:3000"
echo ""
echo "✅ Tests à faire:"
echo "  1. http://localhost:3000 → Page maintenance (visiteur)"
echo "  2. http://localhost:3000/up → Healthcheck (200 OK)"
echo "  3. http://localhost:3000/sessions/new → Login accessible"
echo "  4. Se connecter → Dashboard admin accessible"
echo ""
echo "🛑 Press Ctrl+C to stop"
echo ""

docker run -it --rm \
  -p 3000:80 \
  -e RAILS_ENV=production \
  -e MAINTENANCE_MODE=true \
  -e RAILS_MASTER_KEY=$(cat config/master.key) \
  -e SECRET_KEY_BASE=test_secret_base_for_local_testing_only \
  -e RAILS_SERVE_STATIC_FILES=true \
  circographe-maintenance-test

