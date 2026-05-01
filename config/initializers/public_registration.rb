# frozen_string_literal: true

# Vitrine / pré-prod : désactiver les inscriptions publiques tout en gardant la connexion.
# PUBLIC_REGISTRATION_ENABLED=false | 0 | no | off → désactivé (tout autre valeur ou absent → activé).
# En test : toujours activé au boot (le CI peut exporter false comme en prod). Les specs qui
# couvrent la désactivation repassent config.x à false dans un around.
Rails.application.config.x.public_registration_enabled =
  if Rails.env.test?
    true
  else
    %w[false 0 no off].exclude?(ENV.fetch("PUBLIC_REGISTRATION_ENABLED", "true").to_s.strip.downcase)
  end
