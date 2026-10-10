# frozen_string_literal: true

class OmniauthCallbacksController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 10, within: 3.minutes, only: :create,
              with: -> { redirect_to new_session_path, alert: I18n.t("sessions.rate_limited_alert") }

  def create
    auth = request.env["omniauth.auth"]
    result = Web::OmniauthAuthentication.new(auth: auth).call

    if result.success?
      start_new_session_for(result.user)
      redirect_to after_authentication_url, notice: t("sessions.create.login_success_notice")
    else
      redirect_to new_session_path, alert: result.message
    end
  end

  def failure
    redirect_to new_session_path, alert: t("omniauth_callbacks.failure_alert")
  end
end
