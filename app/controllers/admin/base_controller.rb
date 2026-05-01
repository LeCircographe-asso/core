# frozen_string_literal: true

module Admin
  class BaseController < ApplicationController
    # On évite le before_action global `require_authentication` ici : il ne distingue pas
    # « pas connecté » et « connecté sans rôle staff », ce qui renvoie parfois vers /session/new
    # alors qu’une session cookie existe déjà (compte public). On centralise la logique admin.
    skip_before_action :require_authentication
    before_action :require_admin_zone_access

    private

    def require_admin_zone_access
      resume_session

      unless Current.session
        store_return_location_for_admin_request
        redirect_to new_session_path, alert: I18n.t("admin.base.sign_in_required_alert")
        return
      end

      return if Current.user&.has_privileges?

      redirect_to root_path, alert: I18n.t("admin.base.staff_only_alert")
    end

    def store_return_location_for_admin_request
      uri = URI.parse(request.url)
      path = uri.path.to_s.presence || "/"
      session[:return_to_after_authenticating] = request.url unless non_gettable_redirect_path?(path)
    rescue URI::InvalidURIError
      session[:return_to_after_authenticating] = request.url
    end
  end
end
