# frozen_string_literal: true

module Admin
  module Users
    class UserActionsComponent < ViewComponent::Base
      def initialize(user:, person:, current_user:, is_person_without_user: false, is_deleted: false)
        @user = user
        @person = person
        @is_person_without_user = is_person_without_user
        @is_deleted = is_deleted
        @current_user = current_user
      end

      private

      attr_reader :user, :person, :is_person_without_user, :is_deleted, :current_user

      def primary_actions
        return [] if is_deleted

        actions = []

        # Membership action
        actions << membership_action

        # Subscription action
        actions << subscription_action

        # Create web account action - moved to header
        # if is_person_without_user
        #   actions << create_web_account_action
        # end

        actions.compact
      end

      def secondary_actions
        return [] if is_deleted

        [
          edit_information_action,
          payment_history_action,
          make_donation_action
        ].compact
      end

      def membership_action
        current_membership = person.current_membership

        if current_membership.nil?
          link_to "Ajouter une adhésion",
                  new_admin_membership_path(person_id: person.id),
                  class: "inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-[#1F5C55] hover:bg-[#194A45] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#1F5C55]"
        elsif current_membership.membership_type.basic?
          link_to "Upgrader vers Cirque",
                  new_admin_membership_path(person_id: person.id, upgrade: true),
                  class: "inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-[#1F5C55] hover:bg-[#194A45] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#1F5C55]"
        elsif current_membership.membership_type.circus?
          if current_membership.ended_at < 30.days.from_now
            link_to "Renouveler adhésion",
                    new_admin_membership_path(person_id: person.id, renew: true),
                    class: "inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-[#1F5C55] hover:bg-[#194A45] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#1F5C55]"
          else
            link_to "Voir adhésion",
                    "#{admin_user_path(user ? user.id : "person_#{person.id}")}#membership",
                    class: "inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-[#1F5C55] hover:bg-[#194A45] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#1F5C55]"
          end
        else
          link_to "Renouveler adhésion",
                  new_admin_membership_path(person_id: person.id, renew: true),
                  class: "inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-[#1F5C55] hover:bg-[#194A45] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#1F5C55]"
        end
      end

      def subscription_action
        current_membership = person.current_membership

        if current_membership.nil?
          content_tag :span, "Adhésion requise",
                      class: "inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-500 bg-gray-100"
        elsif current_membership.membership_type.basic?
          content_tag :span, "Adhésion Basique",
                      class: "inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-500 bg-gray-100"
        elsif current_membership.membership_type.circus?
          active_contribution = person.contributions.active.first

          links = []
          if active_contribution
            label = "Voir cotisation"
            if active_contribution.contribution_formula.duration == "pack10"
              remaining_entries = active_contribution.remaining_entries.to_i
              label = "Voir cotisation (#{remaining_entries} restantes)" if remaining_entries.positive?
            end
            links << link_to(
              label,
              "#{admin_user_path(user ? user.id : "person_#{person.id}")}#payments",
              class: "inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-[#1F5C55] hover:bg-[#194A45] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#1F5C55] mr-2"
            )
          end

          links << link_to(
            "Ajouter une cotisation",
            new_admin_subscription_plan_path(person_id: person.id),
            class: "inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-[#1F5C55] hover:bg-[#194A45] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#1F5C55]"
          )

          safe_join(links)
        else
          content_tag :span, "Non applicable",
                      class: "inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-500 bg-gray-100"
        end
      end

      def create_web_account_action
        link_to "Créer un compte web",
                new_admin_user_path(person_id: person.id),
                class: "inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-[#5836a5] hover:bg-[#4c2d8a] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#5836a5]"
      end

      def edit_information_action
        link_to "Modifier les informations",
                edit_person_admin_user_path("person_#{person.id}"),
                class: "text-[#1F5C55] hover:text-[#194A45] hover:underline"
      end

      def payment_history_action
        link_to "Historique des paiements",
                admin_payments_path(person_id: person.id),
                class: "text-[#1F5C55] hover:text-[#194A45] hover:underline"
      end

      def make_donation_action
        link_to "Faire un don",
                new_admin_donation_path(person_id: person.id),
                class: "text-[#1F5C55] hover:text-[#194A45] hover:underline"
      end

      def restore_user_form
        form_tag restore_admin_user_path(user), method: :post, class: "flex items-center" do
          email_field_tag(:email_address, "", placeholder: "Nouvel email", required: true,
                                              class: "border border-gray-300 rounded-md px-3 py-2 shadow-sm focus:outline-none focus:ring-[#1F5C55] focus:border-[#1F5C55] sm:text-sm mr-2") +
            submit_tag("Restaurer l'utilisateur",
                       class: "inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500")
        end
      end

      def delete_action
        # Pour les Person sans User, vérifier les permissions différemment
        if user.nil?
          return unless current_user.has_admin_rights?
        else
          return unless current_user.has_higher_permissions?(user)
        end

        # Vérifier si la personne a des données financières
        if person.has_financial_data?
          return content_tag(:span,
                             "❌ Suppression impossible (données financières)",
                             class: "text-gray-400 text-sm italic cursor-not-allowed",
                             title: "Cette personne a des adhésions actives ou des paiements. Annulez d'abord les adhésions pour pouvoir la supprimer.")
        end

        button_to "Supprimer",
                  admin_user_path(user || "person_#{person.id}"),
                  method: :delete,
                  form: { data: { turbo_confirm: "Êtes-vous sûr de vouloir supprimer cet utilisateur/cette personne ?" } },
                  class: "text-red-600 hover:text-red-800 hover:underline bg-transparent border-none cursor-pointer"
      end
    end
  end
end
