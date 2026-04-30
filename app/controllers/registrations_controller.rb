# frozen_string_literal: true

class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  def new
    redirect_to root_path if authenticated?
    @user = User.new(email_address: session[:newsletter_email])
  end

  def create
    # Utiliser Web::UserRegistration pour créer un espace utilisateur
    result = Web::UserRegistration.new(
      first_name: user_params[:first_name].presence || "Utilisateur",
      last_name: user_params[:last_name].presence || "Anonyme",
      email: user_params[:email_address],
      newsletter_subscribed: user_params[:newsletter_subscribed] == "1",
      user_email: user_params[:email_address],
      user_password: user_params[:password],
      user_password_confirmation: user_params[:password_confirmation],
      user_system_role: "web_visitor",
      cgu: user_params[:cgu],
      privacy_policy: user_params[:privacy_policy]
    ).call

    respond_to do |format|
      if result.success?
        UserMailer.welcome_email(result.user).deliver_later
        start_new_session_for result.user
        format.turbo_stream do
          flash.now[:notice] = "Inscription réussie !"
          render turbo_stream: navigation_streams
        end
        format.html { redirect_to root_path, notice: "Inscription réussie !" }
      else
        # Créer un objet User temporaire pour afficher les erreurs dans la vue
        @user = User.new(user_only_params)

        # Gérer les erreurs spécifiques et ajouter des liens d'aide
        result.errors
        flash.now[:alert] = result.message
        if result.message.include?("Mot de passe oublié")
          flash.now[:help_link] = { text: "Mot de passe oublié", url: new_password_reset_path }
        elsif result.message.include?("Récupérer mon compte")
          flash.now[:help_link] = { text: "Récupérer mon compte", url: new_account_claim_path }
        end

        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("flash", render_to_string(partial: "shared/flash")), status: :unprocessable_content
        end
        format.html do
          render :new, status: :unprocessable_content
        end
      end
    end
  end

  private

  def user_params
    params.expect(user: %i[email_address password password_confirmation cgu privacy_policy newsletter_subscribed first_name last_name])
  end

  def user_only_params
    params.expect(user: %i[email_address password password_confirmation cgu privacy_policy])
  end
end
