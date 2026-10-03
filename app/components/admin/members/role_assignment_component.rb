# frozen_string_literal: true

module Admin
  module Members
    # Rôle d'un compte : sélecteur de changement si current_user a le droit de le
    # modifier (User#can_change_role_of?), simple libellé sinon. Le serveur
    # revalide tout dans UserManagement::RoleChanger.
    class RoleAssignmentComponent < ViewComponent::Base
      def initialize(user:, current_user:)
        @user = user
        @current_user = current_user
      end

      private

      attr_reader :user, :current_user

      def editable?
        current_user.present? && current_user.can_change_role_of?(user)
      end

      # Rôle actuel + rôles attribuables, du plus élevé au plus bas : le rôle
      # actuel reste toujours présélectionné, jamais remplacé en silence.
      def role_options
        roles = [ user.system_role ] | current_user.assignable_roles
        roles.sort_by { |role| User.system_roles[role] }.map { |role| [ role_label(role), role ] }
      end

      def role_label(role)
        t("admin.roles.labels.#{role}")
      end

      def select_id
        "role_system_role_#{user.id}"
      end
    end
  end
end
