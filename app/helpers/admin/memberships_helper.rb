# frozen_string_literal: true

module Admin
  module MembershipsHelper
    def upgrade_name_with_price(membership_type, current_membership:)
      "#{membership_type.name} - #{membership_type.price_euros}€ (plein tarif)"
    end
  end
end
