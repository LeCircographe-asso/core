# frozen_string_literal: true

require_relative "boot"

require "rails/all"
require_relative "../app/middleware/maintenance_mode_middleware"
require_relative "../app/middleware/staging_auth"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Circographe
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    config.i18n.default_locale = :fr
    config.i18n.available_locales = %i[fr en]

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    # config.action_mailer.default_url_options = { host: "circographe.com" }

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot, dir: "spec/factories"
    end

    # Don't generate system test files.
    config.generators.system_tests = nil

    # Configure multi-database setup for Rails 8.0
    # SolidCache, SolidQueue, and SolidCable use separate databases

    # Add Tailwind CSS builds path for Propshaft (for all environments)
    config.assets.paths << Rails.root.join("app/assets/builds")

    # Insert maintenance mode middleware at the top so it intercepts all requests
    config.middleware.insert_before 0, MaintenanceModeMiddleware

    # Insert staging auth middleware (only active when RAILS_ENV=staging or STAGING_MODE=true)
    config.middleware.use StagingAuth
  end
end

Rails.application.configure do
  config.hosts << "lecircographe.fr"
end
