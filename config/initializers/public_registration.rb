# frozen_string_literal: true

# Vitrine / pré-prod : désactiver les inscriptions publiques tout en gardant la connexion.
# PUBLIC_REGISTRATION_ENABLED=false | 0 | no | off → désactivé (tout autre valeur ou absent → activé).
Rails.application.config.x.public_registration_enabled =
  %w[false 0 no off].exclude?(ENV.fetch("PUBLIC_REGISTRATION_ENABLED", "true").to_s.strip.downcase)
