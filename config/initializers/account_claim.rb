# frozen_string_literal: true

# Désactiver la revendication de compte (lien fiche adhérent ↔ espace web) tout en gardant la connexion.
# ACCOUNT_CLAIM_ENABLED=false | 0 | no | off → désactivé (tout autre valeur ou absent → activé).
Rails.application.config.x.account_claim_enabled =
  %w[false 0 no off].exclude?(ENV.fetch("ACCOUNT_CLAIM_ENABLED", "true").to_s.strip.downcase)
