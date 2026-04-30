# frozen_string_literal: true

class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  rate_limit to: 10, within: 3.minutes, only: :create,
              with: -> { redirect_to new_session_url, alert: I18n.t("sessions.rate_limited_alert") }

  def new
    return unless authenticated?

    redirect_to root_path
  end

  def create
    respond_to do |format|
      if (user = User.authenticate_by(params.permit(:email_address, :password)))
        start_new_session_for user
        flash[:notice] = t(".login_success_notice")
        format.turbo_stream { redirect_to after_authentication_url }
        format.html { redirect_to after_authentication_url, notice: t(".login_success_notice") }
      else
        format.turbo_stream do
          flash.now[:alert] = t(".invalid_credentials_flash")
          render turbo_stream: turbo_stream.replace("flash", render_to_string(partial: "shared/flash")), status: :unprocessable_content
        end
        format.html { redirect_to new_session_path, alert: t(".invalid_credentials_redirect") }
      end
    end
  end

  def destroy
    terminate_session
    respond_to do |format|
      flash[:notice] = t(".signed_out_notice")
      format.turbo_stream { redirect_to root_path }
      format.html { redirect_to root_path, notice: t(".signed_out_notice") }
    end
  end
end
