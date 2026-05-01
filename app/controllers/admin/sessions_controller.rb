# frozen_string_literal: true

module Admin
  class SessionsController < BaseController
    skip_before_action :require_admin_zone_access, only: %i[new create]

    rate_limit to: 10, within: 3.minutes, only: :create,
                with: -> { redirect_to new_session_url, alert: I18n.t("admin.sessions.rate_limited_alert") }

    def new
      return redirect_to(root_path, status: :see_other) if authenticated?

      # Pas de vue dédiée : même formulaire que l’espace public.
      redirect_to new_session_path, status: :see_other
    end

    def create
      if (user = User.authenticate_by(params.permit(:email_address, :password)))
        start_new_session_for(user)
        redirect_to after_authentication_url, notice: t(".success"), status: :see_other
      else
        redirect_to new_session_path, alert: t(".invalid_credentials"), status: :see_other
      end
    end

    def destroy
      terminate_session
      Rails.logger.debug "Session terminated"
      redirect_to root_path, notice: t(".signed_out")
    end
  end
end
