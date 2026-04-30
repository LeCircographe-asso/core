source 'https://rubygems.org'

ruby '4.0.1'

# Core Rails gems
gem 'bootsnap', require: false # Reduces boot times through caching
gem 'csv' # Ruby 4+: stdlib gem, required for Admin::ExportsController and others
gem 'rails', '~> 8.1.3'
gem 'stringio', '~> 3.1.2'

# Database and ORM
gem 'bcrypt', '~> 3.1.7' # For password hashing
gem 'sqlite3', '>= 2.1'
gem 'tzinfo-data', platforms: %i[windows jruby] # Timezone data

# Asset Pipeline and Frontend
gem 'image_processing', '~> 1.2' # For Active Storage image processing
gem 'importmap-rails' # JavaScript module imports
gem 'propshaft' # Modern asset pipeline
gem 'stimulus-rails' # Hotwire's JavaScript framework
gem 'tailwindcss-rails', '~> 4.2' # CSS framework
gem 'turbo-rails' # Hotwire's SPA accelerator
gem 'view_component' # Modular UI components

# Server and Performance
gem 'puma', '>= 5.0' # Web server
gem 'thruster', require: false # HTTP asset caching for Puma

# Background Jobs and Caching
gem 'solid_cable'  # Database-backed Action Cable
gem 'solid_cache'  # Database-backed cache
gem 'solid_queue'  # Database-backed job queue

# Pagination
gem 'pagy', '~> 6.0' # Lightweight pagination

# API and External Services
gem 'jbuilder' # JSON API builder
gem 'json', '>= 2.19.2' # Pin patched version for security advisories
gem 'mailjet' # Email service
gem 'rack-cors' # Cross-Origin Resource Sharing
gem 'stripe' # Payment processing

# Development and Testing
group :development, :test do
  gem 'brakeman', require: false # Security scanner
  gem 'bundler-audit', require: false # Security audit for gems
  gem 'debug', platforms: %i[mri windows], require: 'debug/prelude'
  gem 'dotenv-rails' # Environment variables
  gem 'faker' # Generate fake data
  gem 'rubocop' # Code linter
  gem 'rubocop-rake', require: false
  gem 'rubocop-rails-omakase', require: false # Rails-specific linting

  # RSpec testing framework - ESSENTIELS
  gem 'factory_bot_rails'
  gem 'rspec-rails', '~> 8.0.2'
  gem 'shoulda-matchers' # Pour tester les validations Rails
  # gem "database_cleaner-active_record"  # Nettoyage de DB entre tests
end

group :development do
  gem 'letter_opener_web' # Preview emails in browser
  gem 'web-console' # Interactive console
end

group :test do
  # UTILES POUR CI/CD
  gem 'rspec_junit_formatter' # JUnit XML output for CI/CD integration

  # Tests système / Capybara
  gem 'capybara'
  gem 'rails-controller-testing'
  gem 'selenium-webdriver'
  gem 'simplecov', require: false # Couverture de code
end

# Deployment
gem 'kamal', require: false # Docker deployment
