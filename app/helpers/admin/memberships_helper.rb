# frozen_string_literal: true

module Admin
  module MembershipsHelper
    def upgrade_membership_options_for(membership_types)
      membership_types.map { |membership_type| [ membership_type.name_with_price, membership_type.id ] }
    end

    def upgrade_membership_rule_hint
      "Le montant facture correspond a l'adhesion Cirque choisie. Aucun prorata de l'adhesion actuelle n'est deduit."
    end
  end
end
