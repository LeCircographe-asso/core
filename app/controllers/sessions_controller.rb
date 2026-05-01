# frozen_string_literal: true

class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  rate_limit to: 10, within: 3.minutes, only: :create,
              with: -> { redirect_to new_session_url, alert: I18n.t("sessions.rate_limited_alert") }

  def new
    # Déjà connecté·e : ne pas afficher le formulaire (évite la confusion après un POST échoué avec cookie valide).
    return redirect_to(root_path, status: :see_other) if authenticated?
  end

  def create
    # Même logique que #new : si une session cookie est valide, inutile de traiter un « second » login ici.
    return redirect_to(root_path, status: :see_other, notice: t("sessions.already_signed_in_notice")) if authenticated?

    email_address, password = params.expect(:email_address, :password)

    if (user = User.authenticate_by(email_address:, password:))
      start_new_session_for(user)
      # 303 + Turbo : évite les redirections POST ignorées ou sans cookie ; même comportement qu’un POST HTML classique.
      redirect_to after_authentication_url, notice: t(".login_success_notice"), status: :see_other
    else
      log_system_account_login_incident(email_address)
      respond_to do |format|
        format.turbo_stream do
          flash.now[:alert] = t(".invalid_credentials_flash")
          render turbo_stream: turbo_stream.replace("flash", render_to_string(partial: "shared/flash")), status: :unprocessable_content
        end
        format.html { redirect_to new_session_path, alert: t(".invalid_credentials_redirect"), status: :see_other }
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

  private

  def log_system_account_login_incident(email_address)
    return unless Rails.env.development?

    tracked_accounts = %w[super-admin@rails.com admin@rails.com volunteer@rails.com]
    normalized_email = email_address.to_s.strip.downcase
    return unless tracked_accounts.include?(normalized_email)

    DevIncidentLogger.log!(
      type: "system_account_login_failed",
      details: {
        email_address: normalized_email,
        user_exists: User.exists?(email_address: normalized_email),
        users_count: User.count
      }
    )
  end
end
