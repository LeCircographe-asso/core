module Admin
  class BaseController < ApplicationController
    include Pagy::Backend
    before_action :require_admin
    
    private
    
    def require_admin
      unless Current.user&.role.in?(%w[admin godmode])
        redirect_to root_path, alert: "Accès non autorisé"
      end
    end
  end
end
