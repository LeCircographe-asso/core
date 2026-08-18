# frozen_string_literal: true

module Admin
  class HubsController < BaseController
    def memberships
      authorize_administer!
    end

    def pages
      authorize_administer!
    end

    private

    def authorize_administer!
      redirect_to admin_root_path unless current_user.can_administer?
    end
  end
end
