# frozen_string_literal: true

module Admin
  class SessionsController < BaseController
  allow_unauthenticated_access only: %i[new create]
  rate_limit to: 10, within: 3.minutes, only: :create,
               with: -> { redirect_to new_session_url, alert: I18n.t("admin.sessions.rate_limited_alert") }

    def new
      return unless authenticated?

      redirect_to root_path
    end

    def create
      if (user = User.authenticate_by(params.permit(:email_address, :password)))
        start_new_session_for user
        redirect_to after_authentication_url, notice: t(".success")
      else
        redirect_to new_session_path, alert: t(".invalid_credentials")
      end
    end

    def destroy
      terminate_session
      Rails.logger.debug "Session terminated"
      redirect_to root_path, notice: t(".signed_out")
    end
  end
end
