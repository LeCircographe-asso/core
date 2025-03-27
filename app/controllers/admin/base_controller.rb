module Admin
  class BaseController < ApplicationController
    before_action :require_admin_or_super_admin

    private

    def require_admin_or_super_admin
      unless Current.user&.system_role.in?(%w[admin super_admin volunteer])
        redirect_to root_path, alert: "Vous n'avez pas accès à cette page."
      end
    end
  end
end
