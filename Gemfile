source "https://rubygems.org"

ruby "3.2.5"

# Core Rails gems
gem "rails", "~> 8.0.2"
gem "stringio", "~> 3.1.2"
gem "bootsnap", require: false  # Reduces boot times through caching

# Database and ORM
gem "sqlite3", ">= 2.1"
gem "bcrypt", "~> 3.1.7"  # For password hashing
gem "tzinfo-data", platforms: %i[ windows jruby ]  # Timezone data

# Asset Pipeline and Frontend
gem "propshaft"  # Modern asset pipeline
gem "importmap-rails"  # JavaScript module imports
gem "turbo-rails"  # Hotwire's SPA accelerator
gem "stimulus-rails"  # Hotwire's JavaScript framework
gem "tailwindcss-rails", "~> 4.2"  # CSS framework
gem "image_processing", "~> 1.2"  # For Active Storage image processing

# Server and Performance
gem "puma", ">= 5.0"  # Web server
gem "thruster", require: false  # HTTP asset caching for Puma

# Background Jobs and Caching
gem "solid_queue"  # Database-backed job queue
gem "solid_cache"  # Database-backed cache
gem "solid_cable"  # Database-backed Action Cable
gem "whenever", require: false  # Cron jobs

# API and External Services
gem "stripe"  # Payment processing
gem "mailjet"  # Email service
gem "jbuilder"  # JSON API builder
gem "rack-cors"  # Cross-Origin Resource Sharing

# Development and Testing
group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", require: false  # Security scanner
  gem "rubocop"  # Code linter
  gem "rubocop-rails-omakase", require: false  # Rails-specific linting
  gem "faker"  # Generate fake data
  gem "dotenv-rails"  # Environment variables

  # RSpec testing framework
  gem "rspec-rails", "~> 6.1.0"
  gem "factory_bot_rails"
  gem "shoulda-matchers"
  gem "database_cleaner-active_record"
end

group :development do
  gem "web-console"  # Interactive console
  gem "letter_opener"  # Preview emails in development
  gem "letter_opener_web"  # Web interface for letter_opener
  gem "dartsass-rails"
end

group :test do
  gem "capybara"  # System testing
  gem "selenium-webdriver"  # Browser automation
  gem "rspec_junit_formatter"  # JUnit XML output for CI/CD integration
  gem "simplecov", require: false  # Code coverage analysis
end

# Deployment
gem "kamal", require: false  # Docker deployment
