module Admin
  module Users
    class MembershipStatusComponent < ViewComponent::Base
      def initialize(person:)
        @person = person
      end

      private

      attr_reader :person

      def member_number_display
        if person.member_number.present?
          # Numéro actuel avec badge
          current_number = content_tag :span,
            class: "member-number-current px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-indigo-100 text-indigo-800" do
            person.member_number
          end

          # Historique si disponible
          history_count = person.member_number_history.count
          if history_count > 1
            history_badge = content_tag :span,
              class: "member-number-history px-1 inline-flex text-xs leading-4 font-medium rounded bg-gray-100 text-gray-600 ml-1",
              title: "Historique: #{history_count} numéro(s)",
              data: {
                controller: "tooltip",
                tooltip_content: "Historique: #{history_count} numéro(s)"
              } do
              "+#{history_count - 1}"
            end
            current_number + history_badge
          else
            current_number
          end
        else
          content_tag :span,
            class: "member-number-missing px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-gray-100 text-gray-500" do
            "Non assigné"
          end
        end
      end
    end
  end
end
