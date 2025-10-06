require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings.
  config.eager_load = true

  # Show full error reports in staging for debugging.
  config.consider_all_requests_local = true

  # Enable server timing for performance monitoring.
  config.server_timing = true

  # Enable Action Controller caching for better performance.
  config.action_controller.perform_caching = true
  config.action_controller.enable_fragment_cache_logging = true

  # Cache assets for staging (shorter than production).
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.hour.to_i}" }

  # Store uploaded files on the local file system.
  config.active_storage.service = :local

  # SSL configuration for staging (optional, can be disabled for internal staging)
  if ENV.fetch("STAGING_SSL", "false") == "true"
    config.assume_ssl = true
    config.force_ssl = true
  end

  # Log configuration for staging.
  config.log_tags = [ :request_id ]
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "debug")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Show deprecations in staging for debugging.
  config.active_support.deprecation = :log
  config.active_support.report_deprecations = true

  # Use SolidCache for staging (same as production).
  config.cache_store = :solid_cache_store

  # Use SolidQueue for background jobs.
  config.active_job.queue_adapter = :solid_queue
  config.solid_queue.connects_to = { database: { writing: :queue } }

  # Email configuration for staging.
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.perform_deliveries = true
  config.action_mailer.perform_caching = false

  # Staging host configuration.
  staging_host = ENV.fetch("STAGING_HOST", "staging.lecircographe.fr")
  config.action_mailer.default_url_options = { host: staging_host, protocol: "https" }

  # Email delivery method for staging (can use letter_opener for testing).
  if ENV.fetch("STAGING_EMAIL_METHOD", "smtp") == "letter_opener"
    config.action_mailer.delivery_method = :letter_opener
  else
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      user_name: Rails.application.credentials.dig(:staging_smtp, :user_name),
      password: Rails.application.credentials.dig(:staging_smtp, :password),
      address: ENV.fetch("SMTP_ADDRESS", "smtp.example.com"),
      port: ENV.fetch("SMTP_PORT", 587),
      authentication: :plain,
      enable_starttls_auto: true
    }
  end

  # Database configuration.
  config.active_record.dump_schema_after_migration = false
  config.active_record.migration_error = :page_load

  # Host authorization for staging.
  config.hosts = [
    staging_host,
    "localhost",
    "127.0.0.1",
    /.*\.staging\.lecircographe\.fr/ # Allow staging subdomains
  ]

  # Enable public file server for staging.
  config.public_file_server.enabled = true

  # Staging-specific optimizations.
  config.active_record.verbose_query_logs = true
  config.active_job.verbose_enqueue_logs = true
end
