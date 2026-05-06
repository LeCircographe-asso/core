# frozen_string_literal: true

module Admin
  module Members
    class MemberNumberChangeComponent < ViewComponent::Base
      def initialize(person:, current_user:)
        @person = person
        @current_user = current_user
      end

      private

      attr_reader :person, :current_user

      def can_edit?
        current_user&.can_edit_member_numbers?
      end

      def current_member_number
        person.member_number
      end

      def membership_type_options
        [
          [ "Basique (U)", "BASIQUE" ],
          [ "Cirque (C)", "CIRQUE" ]
        ]
      end

      def suggested_member_number(membership_type)
        MemberManagementService.generate_member_number(membership_type)
      end

      def current_membership_type
        if person.current_membership&.membership_type&.circus?
          "CIRQUE"
        else
          "BASIQUE"
        end
      end
    end
  end
end
