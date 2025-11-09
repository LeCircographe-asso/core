module Admin
  module Users
    class ActionButtonsComponent < ViewComponent::Base
      def initialize(person:)
        @person = person
      end

      private

      attr_reader :person

      def membership_action_button
        current_membership = person.current_membership

        if current_membership.nil?
          # Pas d'adhésion active
          link_to "Ajouter une adhésion",
                  new_admin_membership_path(person_id: person.id),
                  class: "inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-[#1F5C55] hover:bg-[#194A45] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#1F5C55]"
        elsif current_membership.membership_type.basic?
          # Adhésion basique -> peut upgrader vers cirque
          link_to "Upgrader vers Cirque",
                  new_admin_membership_path(person_id: person.id, upgrade: true),
                  class: "inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-[#1F5C55] hover:bg-[#194A45] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#1F5C55]"
        elsif current_membership.membership_type.circus?
          # Adhésion cirque -> peut renouveler
          if current_membership.ended_at < 30.days.from_now
            link_to "Renouveler adhésion",
                    new_admin_membership_path(person_id: person.id, renew: true),
                    class: "inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-[#1F5C55] hover:bg-[#194A45] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#1F5C55]"
          else
            # Adhésion cirque valide -> pas de bouton
            content_tag :span, "Adhésion Cirque active",
                        class: "inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-500 bg-gray-100"
          end
        else
          # Autres cas -> renouveler
          link_to "Renouveler adhésion",
                  new_admin_membership_path(person_id: person.id, renew: true),
                  class: "inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-[#1F5C55] hover:bg-[#194A45] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#1F5C55]"
        end
      end

      def subscription_action_button
        current_membership = person.current_membership

        if current_membership.nil?
          # Pas d'adhésion -> pas de cotisation possible
          content_tag :span, "Adhésion requise",
                      class: "inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-500 bg-gray-100"
        elsif current_membership.membership_type.basic?
          # Adhésion basique -> pas de cotisation
          content_tag :span, "Adhésion Basique",
                      class: "inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-500 bg-gray-100"
        elsif current_membership.membership_type.circus?
          # Adhésion cirque -> peut ajouter des cotisations
          active_book = person.book_of_entries.active.first

          buttons = []
          if active_book && active_book.remaining_entries > 0
            buttons << link_to(
              "Voir cotisation (#{active_book.remaining_entries} restantes)",
              admin_user_path(person.user ? person.user.id : "person_#{person.id}"),
              class: "inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-[#1F5C55] hover:bg-[#194A45] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#1F5C55] mr-2"
            )
          end

          buttons << link_to(
            "Ajouter une cotisation",
            new_admin_subscription_plan_path(person_id: person.id),
            class: "inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-[#1F5C55] hover:bg-[#194A45] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#1F5C55]"
          )

          safe_join(buttons)
        else
          # Autres cas
          content_tag :span, "Non applicable",
                      class: "inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-500 bg-gray-100"
        end
      end
    end
  end
end
