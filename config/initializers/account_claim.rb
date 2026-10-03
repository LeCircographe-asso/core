# frozen_string_literal: true

# Revendication de compte (lien fiche adhérent ↔ espace web) : feature non aboutie,
# désactivée par défaut tant que le flow session/inscription/reset password n'est
# pas retravaillé (voir #543 pour le bug de prise de compte qu'elle contenait).
# ACCOUNT_CLAIM_ENABLED=true | 1 | yes | on → réactivé explicitement.
Rails.application.config.x.account_claim_enabled =
  %w[true 1 yes on].include?(ENV.fetch("ACCOUNT_CLAIM_ENABLED", "false").to_s.strip.downcase)
