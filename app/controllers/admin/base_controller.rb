module Admin
  class BaseController < ApplicationController
    layout "admin"
    before_action :require_admin_or_godmode

    private

    def require_admin_or_godmode
      unless Current.user&.role.in?(%w[admin godmode volunteer])
        redirect_to root_path, alert: "Vous n'avez pas accès à cette page."
      end
    end
  end
end
