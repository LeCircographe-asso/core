# Configuration pour l'environnement staging
Rails.application.configure do
  # Environnement
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local = false
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?

  # Logging
  config.log_level = :info
  config.log_tags = [ :request_id ]

  # Cache
  config.cache_store = :memory_store
  config.public_file_server.headers = {
    "Cache-Control" => "public, max-age=#{1.hour.to_i}"
  }

  # Assets
  config.assets.compile = false
  config.assets.digest = true

  # Force SSL
  config.force_ssl = true

  # Mailer
  config.action_mailer.perform_caching = false
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.default_url_options = {
    host: "staging.lecircographe.fr",
    protocol: "https"
  }

  # Database
  config.active_record.dump_schema_after_migration = false

  # Staging specific
  config.staging_mode = true

  # Désactiver certaines fonctionnalités en staging
  config.disable_payments = true
  config.disable_emails = true

  # Logs spécifiques
  config.logger = ActiveSupport::Logger.new(STDOUT)
  config.logger.formatter = proc do |severity, datetime, progname, msg|
    "[STAGING] #{datetime.strftime('%Y-%m-%d %H:%M:%S')} #{severity}: #{msg}\n"
  end
end
