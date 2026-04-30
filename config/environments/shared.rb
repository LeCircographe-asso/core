# Configuration partagée entre tous les environnements
# Ce fichier est inclus dans chaque environnement pour éviter la duplication

module SharedEnvironmentConfig
  extend ActiveSupport::Concern

  included do
    # Assets configuration
    # Note: In Rails 8.1, assets.paths is frozen - configured via Propshaft instead
    # config.assets.paths << Rails.root.join("app", "assets", "builds")

    # Tailwind CSS builds path for Propshaft
    config.assets.precompile += %w[.svg .eot .woff .ttf .woff2 .otf]

    # Performance optimizations
    config.force_ssl = true
    config.ssl_options = { redirect: { exclude: ->(request) { request.path == '/up' } } }

    # Host Authorization for Docker containers
    config.hosts.clear if Rails.env.production? || Rails.env.staging?

    # Logging
    config.log_tags = [:request_id]

    # Cache configuration
    config.cache_store = :solid_cache_store if Rails.env.production? || Rails.env.staging?

    # Job queue configuration
    config.active_job.queue_adapter = :solid_queue if Rails.env.production? || Rails.env.staging?

    # Database configuration
    config.active_record.dump_schema_after_migration = false
  end
end

# Shared configuration applied to all environments
# (Module SharedEnvironmentConfig removed - was causing build errors)
