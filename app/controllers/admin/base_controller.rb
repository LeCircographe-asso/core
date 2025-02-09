module Admin
  class BaseController < ApplicationController
    include ActionController::MimeResponds
    
    layout "admin"
    before_action :require_admin_or_godmode

    private

    def require_admin_or_godmode
      unless Current.user&.has_privileges?
        redirect_to root_path, alert: "Vous n'avez pas accès à cette page."
      end
    end
  end
end
