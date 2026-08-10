# frozen_string_literal: true

module Admin
  module MembershipsHelper
    # Options avec un data-attribute repéré par le contrôleur Stimulus "reduced-rate"
    # (app/javascript/controllers/reduced_rate_controller.js) pour révéler le champ
    # de justificatif dès qu'un type d'adhésion à tarif réduit est sélectionné.
    def membership_type_select_options(membership_types)
      membership_types.map do |membership_type|
        [ membership_type.name_with_price, membership_type.id, { data: { reduced_rate: membership_type.reduced_rate? } } ]
      end
    end

    def upgrade_membership_rule_hint
      "Le montant facture correspond a l'adhesion Cirque choisie. Aucun prorata de l'adhesion actuelle n'est deduit."
    end
  end
end
