# Configuration Puma pour Production - VPS Ionos Linux M
workers 2
threads 4, 4

# Port et binding
port ENV.fetch("PORT", 80)
bind "tcp://0.0.0.0:#{ENV.fetch('PORT', 80)}"

# Environnement
environment ENV.fetch("RAILS_ENV", "production")

# Préchargement de l'application
preload_app!

# Logs
stdout_redirect "/app/log/puma.stdout.log", "/app/log/puma.stderr.log", true

# PID
pidfile "/app/tmp/pids/puma.pid"
state_path "/app/tmp/pids/puma.state"

# Configuration pour VPS avec ressources limitées
worker_timeout 30
worker_boot_timeout 30

# Gestion des signaux
on_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end

# Configuration spécifique production
before_fork do
  ActiveRecord::Base.connection_pool.disconnect! if defined?(ActiveRecord)
end

# Performance optimisée pour production
log_requests false
