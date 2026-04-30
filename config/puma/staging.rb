# frozen_string_literal: true

# Configuration Puma pour Staging - VPS Ionos Linux M
# workers défini via WEB_CONCURRENCY dans puma.rb (0 pour staging)
threads 2, 2

# Port et binding - utilise la config de puma.rb
# port ENV.fetch("PORT", 80)  # Déjà défini dans puma.rb
# bind "tcp://0.0.0.0:80"     # Déjà défini dans puma.rb

# Environnement
environment ENV.fetch('RAILS_ENV', 'staging')

# Préchargement de l'application
preload_app!

# Logs - DÉSACTIVÉ pour éviter les erreurs de permissions
# stdout_redirect "/app/log/puma.stdout.log", "/app/log/puma.stderr.log", true

# PID - utilise tmp/rails au lieu de /app/tmp
pidfile ENV.fetch('PIDFILE', 'tmp/pids/puma.pid')
state_path 'tmp/pids/puma.state'

# Configuration pour VPS avec ressources limitées
worker_timeout 30
worker_boot_timeout 30

# Gestion des signaux
on_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end

# Configuration spécifique staging
before_fork do
  ActiveRecord::Base.connection_pool.disconnect! if defined?(ActiveRecord)
end

# Logs détaillés pour staging
log_requests true
