#!/bin/bash

# Script de gestion du mode maintenance (local/staging/production)
# - Affiche le statut (fichier + variable + HTTP)
# - Propose de basculer (enable/disable) puis re-teste
# Usage:
#   Interactive (par défaut): ./scripts/maintenance.sh [local|staging|production]
#   Commandes directes:       ./scripts/maintenance.sh [status|enable|disable] [local|staging|production]

set -euo pipefail

APP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCAL_FLAG_PATH="${APP_ROOT}/tmp/maintenance.flag"
LEGACY_FLAG_PATH="/tmp/maintenance"
REMOTE_FLAG_RELATIVE_PATH="tmp/maintenance.flag"

ACTION=""
ENVIRONMENT=""

# Parse simple args
if [[ $# -eq 0 ]]; then
  ACTION="interactive"
  ENVIRONMENT="local"
elif [[ $# -eq 1 ]]; then
  case "$1" in
    status|enable|disable) ACTION="$1"; ENVIRONMENT="local" ;;
    local|staging|production) ACTION="interactive"; ENVIRONMENT="$1" ;;
    *) ACTION="interactive"; ENVIRONMENT="local" ;;
  esac
else
  ACTION="$1"
  ENVIRONMENT="$2"
fi

CONFIG_FILE=""
BASE_URL=""

case "$ENVIRONMENT" in
  local)
    # Local: on manipule tmp/maintenance.flag et on teste le serveur dev
    CONFIG_FILE=""
    BASE_URL="http://127.0.0.1:3000"
    ;;
  staging)
    CONFIG_FILE="config/deploy.staging.yml"
    BASE_URL="https://staging.lecircographe.fr"
    ;;
  production)
    CONFIG_FILE="config/deploy.yml"
    BASE_URL="https://lecircographe.fr"
    ;;
  *)
    echo "❌ Environnement invalide. Utilisez local|staging|production"
    exit 1
    ;;
esac

title() { echo "\n🔧 Maintenance — ${ENVIRONMENT}"; }

http_status() {
  local url="$1"
  curl -s -o /dev/null -w "%{http_code}" "$url" || echo "000"
}

flag_present_local() {
  [[ -f "${LOCAL_FLAG_PATH}" ]] || [[ -f "${LEGACY_FLAG_PATH}" ]]
}

flag_present_remote() {
  kamal app exec -c "$CONFIG_FILE" "test -f '${REMOTE_FLAG_RELATIVE_PATH}'" 2>/dev/null
}

show_status() {
  title
  echo "📍 URL: ${BASE_URL}"
  if [[ "$ENVIRONMENT" == "local" ]]; then
    if flag_present_local; then
      echo "📁 maintenance flag: présent (${LOCAL_FLAG_PATH})"
    else
      echo "📁 maintenance flag: absent (${LOCAL_FLAG_PATH})"
    fi
    echo "🔧 MAINTENANCE_MODE (process local): ${MAINTENANCE_MODE:-non définie}"
  else
    # distant via kamal
    if flag_present_remote; then
      echo "📁 maintenance flag (remote): présent (${REMOTE_FLAG_RELATIVE_PATH})"
    else
      echo "📁 maintenance flag (remote): absent (${REMOTE_FLAG_RELATIVE_PATH})"
    fi
    REMOTE_ENV=$(kamal app exec -c "$CONFIG_FILE" "echo \$MAINTENANCE_MODE" 2>/dev/null || true)
    if [[ -z "$REMOTE_ENV" ]]; then REMOTE_ENV="non définie"; fi
    echo "🔧 MAINTENANCE_MODE (remote): $REMOTE_ENV"
  fi

  local code
  code=$(http_status "$BASE_URL")
  case "$code" in
    503) echo "🚧 HTTP: 503 (maintenance)" ;;
    200) echo "✅ HTTP: 200 (actif)" ;;
    *)   echo "❓ HTTP: $code" ;;
  esac
}

enable_remote() {
  kamal app exec -c "$CONFIG_FILE" "sh -lc 'mkdir -p tmp && echo true > ${REMOTE_FLAG_RELATIVE_PATH}'"
}

disable_remote() {
  kamal app exec -c "$CONFIG_FILE" "rm -f ${REMOTE_FLAG_RELATIVE_PATH}"
}

enable_local() {
  mkdir -p "$(dirname "${LOCAL_FLAG_PATH}")"
  echo true > "${LOCAL_FLAG_PATH}"
  echo true > "${LEGACY_FLAG_PATH}"
}

disable_local() {
  rm -f "${LOCAL_FLAG_PATH}" || true
  rm -f "${LEGACY_FLAG_PATH}" || true
}

toggle_interactive() {
  # Détecte état courant via HTTP 503 d'abord, sinon via fichier
  local current="off"
  local code
  code=$(http_status "$BASE_URL")
  if [[ "$code" == "503" ]]; then
    current="on"
  else
    if [[ "$ENVIRONMENT" == "local" ]]; then
      flag_present_local && current="on"
    else
      if flag_present_remote; then current="on"; fi
    fi
  fi
  echo "\nEtat actuel: $( [[ "$current" == "on" ]] && echo '🚧 maintenance ON' || echo '✅ maintenance OFF' )"
  read -r -p "Basculer l'état ? [y/N] " ans
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    if [[ "$current" == "on" ]]; then
      [[ "$ENVIRONMENT" == "local" ]] && disable_local || disable_remote
      echo "➡️  Désactivation demandée"
    else
      [[ "$ENVIRONMENT" == "local" ]] && enable_local || enable_remote
      echo "➡️  Activation demandée"
    fi
  else
    echo "Aucun changement."
  fi
  echo "\n🔁 Re-test:"
  show_status
}

case "$ACTION" in
  status)
    show_status
    ;;
  enable)
    [[ "$ENVIRONMENT" == "local" ]] && enable_local || enable_remote
    show_status
    ;;
  disable)
    [[ "$ENVIRONMENT" == "local" ]] && disable_local || disable_remote
    show_status
    ;;
  interactive)
    show_status
    toggle_interactive
    ;;
  *)
    echo "Usage: $0 [status|enable|disable] [local|staging|production]"
    echo "       $0 [local|staging|production] # mode interactif"
    exit 1
    ;;
esac
