# frozen_string_literal: true

# Configuration pour l'environnement staging
require_relative 'shared'

Rails.application.configure do
  # Use the default credentials secret_key_base for staging
  # Rails will use config/credentials.yml.enc with RAILS_MASTER_KEY
  # Allow ENV override for Docker build (asset compilation)
  config.secret_key_base = ENV['SECRET_KEY_BASE'] || Rails.application.credentials.secret_key_base

  # Environnement
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.public_file_server.enabled = true

  # Logging
  config.log_level = :info
  config.log_tags = [:request_id]

  # Cache
  config.cache_store = :memory_store
  config.public_file_server.headers = {
    'Cache-Control' => "public, max-age=#{1.hour.to_i}"
  }

  # Host Authorization - Allow kamal-proxy container hostnames
  # kamal-proxy uses Docker container IDs as hostnames (e.g., f4753d38178e)
  config.hosts.clear # Allow all hosts in staging for Docker container communication

  # SSL configuration
  config.force_ssl = true
  config.ssl_options = { redirect: { exclude: ->(request) { request.path == '/up' } } }

  # Mailer
  config.action_mailer.perform_caching = false
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.default_url_options = {
    host: 'staging.lecircographe.fr',
    protocol: 'https'
  }

  # Database
  config.active_record.dump_schema_after_migration = false

  # Staging specific
  # Note: Custom configs comme staging_mode doivent être définies dans application.rb
  # ou via des initializers si nécessaire

  # Logs spécifiques
  config.logger = ActiveSupport::Logger.new($stdout)
  config.logger.formatter = proc do |severity, datetime, _progname, msg|
    "[STAGING] #{datetime.strftime('%Y-%m-%d %H:%M:%S')} #{severity}: #{msg}\n"
  end
end
