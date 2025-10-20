module Admin
  module Users
    class MembershipStatusBadgeComponent < ViewComponent::Base
      def initialize(person:)
        @person = person
      end

      private

      attr_reader :person

      def badge_class
        if person.has_active_membership?
          "status-badge px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800 cursor-help"
        elsif person.memberships.exists?
          "status-badge px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-yellow-100 text-yellow-800 cursor-help"
        else
          "status-badge px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-gray-100 text-gray-800"
        end
      end

      def status_text
        if person.has_active_membership?
          "✓ Actif"
        elsif person.memberships.exists?
          "⚠ Expiré"
        else
          "✗ Aucune"
        end
      end

      def tooltip_text
        if person.has_active_membership?
          current_membership = person.current_membership
          "Adhésion #{current_membership.membership_type.name} - Expire le #{current_membership.ended_at.strftime('%d/%m/%Y')}"
        elsif person.memberships.exists?
          last_membership = person.memberships.order(:created_at).last
          "Adhésion #{last_membership.membership_type.name} expirée le #{last_membership.ended_at.strftime('%d/%m/%Y')}"
        else
          "Aucune adhésion"
        end
      end

      def tooltip_data
        if person.has_active_membership? || person.memberships.exists?
          {
            controller: "tooltip",
            tooltip_content: tooltip_text
          }
        else
          {}
        end
      end
    end
  end
end
