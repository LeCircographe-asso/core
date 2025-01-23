source "https://rubygems.org"

ruby "3.2.5"

################################
# GEMS RAILS DE BASE
################################
gem "rails", "~> 8.0.0.1"
gem "puma", ">= 5.0"
gem "sqlite3", ">= 2.1"
gem "bootsnap", require: false
gem "tzinfo-data", platforms: %i[windows jruby]

################################
# FRONTEND & ASSETS
################################
gem "propshaft"                    # Asset pipeline moderne
gem "importmap-rails"              # Import maps pour JavaScript
gem "turbo-rails"                  # SPA-like avec Hotwire
gem "stimulus-rails"               # Framework JavaScript minimaliste
gem "jbuilder"                     # Construction d'API JSON
gem "flatpickr"                  # Sélecteur de date/heure
gem "flatpickr_rails"              # Sélecteur de date/heure

################################
# AUTHENTIFICATION & SÉCURITÉ
################################
gem "bcrypt", "~> 3.1.7"          # Hashage des mots de passe
gem "brakeman", require: false     # Analyse de sécurité

################################
# PERFORMANCE & CACHE
################################
gem "solid_cache"                  # Cache avec base de données
gem "solid_queue"                  # File d'attente avec base de données
gem "solid_cable"                  # Action Cable avec base de données
gem "thruster", require: false     # Optimisation HTTP pour Puma

################################
# DÉPLOIEMENT & DEVOPS
################################
gem "kamal", require: false        # Déploiement Docker
gem "whenever", require: false     # Gestion des tâches cron

################################
# PAIEMENT & SERVICES EXTERNES
################################
gem "stripe"                       # Intégration Stripe
gem "actionmailer"                 # Gestion des emails

################################
# UTILITAIRES
################################
gem "dotenv-rails"                 # Variables d'environnement

# Pour la pagination
gem "pagy"

group :development, :test do
  # DEBUGGING & QUALITÉ DE CODE
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "rubocop-rails-omakase", require: false

  # TESTING FRAMEWORK
  gem "rspec-rails"                # Framework de test
  gem "factory_bot_rails"          # Création d'objets de test
  gem "faker"                      # Données de test aléatoires
  gem "shoulda-matchers"           # Assertions plus lisibles
  gem "timecop"                    # Tests avec manipulation du temps
end

group :development do
  gem "web-console"                # Console de débogage dans le navigateur
end

group :test do
  # TESTS SYSTÈME
  gem "capybara"                   # Tests d'intégration
  gem "selenium-webdriver"         # Pilote de navigateur pour tests
end

################################
# GEMS OPTIONNELLES (COMMENTÉES)
################################
# gem "image_processing", "~> 1.2"  # Traitement d'images
# gem "redis", ">= 4.0.1"           # Cache Redis
# gem "sidekiq"                     # Background jobs
# gem "aws-sdk-s3"                  # Stockage sur Amazon S3
# gem "sentry-ruby"                 # Monitoring d'erreurs
# gem "rack-cors"                   # Support CORS pour API
# gem "paper_trail"                 # Historique des modifications
# gem "friendly_id"                 # URLs propres
# gem "kaminari"                    # Pagination
# gem "ransack"                     # Recherche avancée
