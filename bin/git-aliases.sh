#!/usr/bin/env bash
# bin/git-aliases.sh
# Aliases Git pour le workflow Le Circographe
#
# Installation (ajouter à ~/.zshrc) :
#   source /home/aka/Final_Project/le_circographe/bin/git-aliases.sh
#
# Ou one-liner :
#   echo 'source /home/aka/Final_Project/le_circographe/bin/git-aliases.sh' >> ~/.zshrc

# --- Nouvelle branche feature depuis dev à jour ---
# Usage: zf membres-export
zf() {
  local name="$1"
  if [ -z "$name" ]; then
    echo "Usage: zf <nom-de-la-feature>"
    return 1
  fi
  git checkout dev && git pull --rebase origin dev
  git checkout -b "feature/${name}"
  echo "✅ Branche feature/${name} créée depuis dev"
}

# --- Push + sync rebase sur dev ---
# Usage: zp (sur une branche feature)
zp() {
  local branch
  branch=$(git branch --show-current)
  if [[ "$branch" == "dev" || "$branch" == "staging" || "$branch" == "main" ]]; then
    echo "❌ Ne pas utiliser zp sur $branch directement"
    return 1
  fi
  git fetch origin dev
  git rebase origin/dev
  git push --force-with-lease origin "$branch"
  echo "✅ $branch poussée et rebasée sur dev"
}

# --- Tests rapides locaux ---
# Usage: zt
zt() {
  bin/test_fast
}

# --- Tests complets locaux ---
# Usage: zta
zta() {
  bundle exec rspec
}

# --- Reset complet de la base locale ---
# Usage: circodb
circodb() {
  bin/rails db:drop &&
    sleep 1 &&
    bin/rails db:create &&
    bin/rails db:migrate &&
    bin/rails db:seed
}

# --- Statut du workflow (dernier run CI sur la branche courante) ---
# Usage: zci
zci() {
  local branch
  branch=$(git branch --show-current)
  gh run list --branch "$branch" --limit 5
}

# --- Voir la PR de la branche courante ---
# Usage: zpr
zpr() {
  gh pr view --web 2>/dev/null || echo "Pas de PR ouverte pour cette branche."
}

# --- Marquer la PR courante comme prête (draft → ready) ---
# Usage: zready
zready() {
  gh pr ready && echo "✅ PR marquée comme prête pour review"
}

# --- Promotion vers staging (via workflow GitHub) ---
# Usage: zpromote staging
# Usage: zpromote main
zpromote() {
  local target="$1"
  case "$target" in
    staging)
      gh workflow run deploy-promote-staging.yml -f confirm_promote=PROMOTE
      echo "🚀 Promotion dev→staging lancée"
      ;;
    main)
      gh workflow run deploy-promote-main.yml -f confirm_promote=PROMOTE
      echo "🚀 Promotion staging→main lancée"
      ;;
    *)
      echo "Usage: zpromote [staging|main]"
      return 1
      ;;
  esac
}

# --- Log compact avec graph ---
# Usage: zlog
alias zlog='git log --oneline --graph --decorate --all -20'

# --- Nettoyer les branches mergées en local ---
# Usage: zclean
zclean() {
  git fetch --prune
  git branch --merged dev | grep -v '^\*\|dev\|staging\|main' | xargs -r git branch -d
  echo "✅ Branches locales mergées supprimées"
}

echo "✅ Aliases Le Circographe chargés (zf, zp, zt, zta, circodb, zci, zpr, zready, zpromote, zlog, zclean)"
