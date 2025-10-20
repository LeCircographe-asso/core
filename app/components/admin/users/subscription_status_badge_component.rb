module Admin
  module Users
    class SubscriptionStatusBadgeComponent < ViewComponent::Base
      def initialize(person:)
        @person = person
      end

      private

      attr_reader :person

      def badge_class
        if has_active_subscriptions?
          "px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-indigo-100 text-indigo-800 cursor-help"
        else
          "px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-gray-100 text-gray-800"
        end
      end

      def badge_text
        if has_active_subscriptions?
          "#{total_sessions} séances"
        else
          "Aucune"
        end
      end

      def tooltip_text
        if has_active_subscriptions?
          "#{total_sessions} séances restantes"
        else
          ""
        end
      end

      def tooltip_data
        if has_active_subscriptions?
          {
            controller: "tooltip",
            tooltip_content: tooltip_text
          }
        else
          {}
        end
      end

      def has_active_subscriptions?
        person.book_of_entries.active.any?
      end

      def total_sessions
        person.book_of_entries.active.sum(&:sessions_remaining)
      end
    end
  end
end
