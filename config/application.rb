require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Circographe
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

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

    # Use classic autoloader for RSpec compatibility with Rails 8.0
    config.autoloader = :classic

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot, dir: "spec/factories"
    end

    # Don't generate system test files.
    config.generators.system_tests = nil

    # Configure multi-database setup
    if Rails.env.production?
      # Configure database connections for various services
      config.solid_cache.connects_to = { database: { writing: :"#{Rails.env}_cache", reading: :"#{Rails.env}_cache" } }
      config.solid_queue.connects_to = { database: { writing: :"#{Rails.env}_queue", reading: :"#{Rails.env}_queue" } }
      config.action_cable.cable_connection_class = -> { ActionCable::Connection::Base.establish_connection(adapter: "sqlite3", database: "storage/#{Rails.env}_cable.sqlite3") }
    else
      # Development/test configuration
      config.solid_cache.connects_to = { database: { writing: :"#{Rails.env}_cache", reading: :"#{Rails.env}_cache" } }
      config.solid_queue.connects_to = { database: { writing: :"#{Rails.env}_queue", reading: :"#{Rails.env}_queue" } }
    end
  end
end

Rails.application.configure do
  config.hosts << "lecircographe.fr"
end