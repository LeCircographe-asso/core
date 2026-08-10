# frozen_string_literal: true

module Admin
  module Members
    class MemberActionsComponent < ViewComponent::Base
      def initialize(person:, current_user:, is_deleted: false)
        @person = person
        @is_deleted = is_deleted
        @current_user = current_user
      end

      private

      attr_reader :person, :is_deleted, :current_user

      def user
        person.user
      end

      def primary_actions
        return [] if is_deleted

        [
          membership_action,
          contribution_action,
          (create_web_account_action if user.nil?)
        ].compact
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

        btn_class = "inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-[#1F5C55] hover:bg-[#194A45] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#1F5C55]"

        if current_membership.nil?
          link_to "Ajouter une adhésion", new_admin_membership_path(person_id: person.id), class: btn_class
        elsif current_membership.membership_type.basic?
          link_to "Passer en adhésion Cirque", new_admin_membership_path(person_id: person.id, upgrade: true), class: btn_class
        elsif current_membership.membership_type.circus?
          if current_membership.ended_at < 30.days.from_now
            link_to "Renouveler l'adhésion", new_admin_membership_path(person_id: person.id, renew: true), class: btn_class
          else
            link_to "Voir adhésion", "#{admin_member_path(person)}#membership", class: btn_class
          end
        else
          link_to "Renouveler l'adhésion", new_admin_membership_path(person_id: person.id, renew: true), class: btn_class
        end
      end

      def contribution_action
        current_membership = person.current_membership
        btn_class = "inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-[#1F5C55] hover:bg-[#194A45] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#1F5C55]"
        disabled_class = "inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-500 bg-gray-100"

        if current_membership.nil?
          content_tag :span, "Adhésion requise", class: disabled_class
        elsif current_membership.membership_type.basic?
          content_tag :span, "Adhésion Basique", class: disabled_class
        elsif current_membership.membership_type.circus?
          active_contribution = person.contributions.active.first
          links = []
          if active_contribution
            label = "Voir cotisation"
            if active_contribution.contribution_formula.duration == "pack10"
              remaining = active_contribution.remaining_entries.to_i
              label = "Voir cotisation (#{remaining} restantes)" if remaining.positive?
            end
            links << link_to(label, "#{admin_member_path(person)}#payments", class: "#{btn_class} mr-2")
          end
          links << link_to(contribution_action_label, new_admin_contribution_path(person_id: person.id), class: btn_class)
          helpers.safe_join(links)
        else
          content_tag :span, "Non applicable", class: disabled_class
        end
      end

      def create_web_account_action
        if person.email.present?
          helpers.button_to(
            "Créer un compte web",
            helpers.create_web_account_admin_member_path(person),
            method: :post,
            form: { data: { turbo_confirm: "Créer un compte web dormant pour #{person.full_name} (#{person.email}) ?" } },
            class: "inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-[#5836a5] hover:bg-[#4c2d8a] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#5836a5]"
          )
        else
          content_tag :span,
                      "Compte web (email requis)",
                      class: "inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-400 bg-gray-50 cursor-not-allowed",
                      title: "Renseignez un email dans le profil pour activer cette action"
        end
      end

      def edit_information_action
        link_to "Modifier les informations",
                edit_person_admin_member_path(person),
                class: "text-[#1F5C55] hover:text-[#194A45] hover:underline"
      end

      def payment_history_action
        link_to "Voir les paiements",
                admin_payments_path(person_id: person.id),
                class: "text-[#1F5C55] hover:text-[#194A45] hover:underline"
      end

      def make_donation_action
        link_to "Enregistrer un don",
                new_admin_donation_path(person_id: person.id),
                class: "text-[#1F5C55] hover:text-[#194A45] hover:underline"
      end

      def restore_user_form
        form_tag restore_admin_member_path(person), method: :post, class: "flex items-center" do
          email_field_tag(:email_address, "", placeholder: "Nouvel email", required: true,
                                              class: "border border-gray-300 rounded-md px-3 py-2 shadow-sm focus:outline-none focus:ring-[#1F5C55] focus:border-[#1F5C55] sm:text-sm mr-2") +
            submit_tag("Restaurer l'utilisateur",
                       class: "inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500")
        end
      end

      def delete_action
        if user.nil?
          return unless current_user.can_administer?
        else
          return unless current_user.has_higher_permissions?(user)
        end

        if person.has_financial_data?
          return content_tag(:span,
                             "Suppression impossible (données financières)",
                             class: "text-gray-400 text-sm italic cursor-not-allowed",
                             title: "Cette personne a des adhésions actives ou des paiements. Annulez d'abord les adhésions pour pouvoir la supprimer.")
        end

        button_to "Supprimer",
                  admin_member_path(person),
                  method: :delete,
                  form: { data: { turbo_confirm: "Êtes-vous sûr de vouloir supprimer cette personne ?" } },
                  class: "text-red-600 hover:text-red-800 hover:underline bg-transparent border-none cursor-pointer"
      end

      def contribution_action_label
        active_contribution = person.contributions.active.first
        return "Acheter une cotisation" unless active_contribution
        return "Gérer les cotisations" unless active_contribution.contribution_formula.duration == "pack10"

        remaining = active_contribution.remaining_entries.to_i
        return "Gérer les cotisations" unless remaining.positive?

        "Gérer les cotisations (#{remaining} restantes)"
      end
    end
  end
end
