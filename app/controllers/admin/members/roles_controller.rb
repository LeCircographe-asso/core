# frozen_string_literal: true

module Admin
  module Members
    class RolesController < BaseController
      before_action :require_admin_rights
      before_action :set_person

      def update
        user = @person.user
        if user.nil?
          redirect_back_or_to admin_member_path(@person), alert: t("admin.roles.no_web_account"), status: :see_other
          return
        end

        result = UserManagement::RoleChanger.new(
          user_id: user.id,
          system_role: params.expect(role: [ :system_role ])[:system_role],
          changed_by_id: Current.user.id
        ).call

        flash_key = result.success? ? :notice : :alert
        redirect_back_or_to admin_member_path(@person), flash_key => result.message, status: :see_other
      end

      private

      def set_person
        @person = Person.find(params.expect(:member_id))
      end
    end
  end
end
