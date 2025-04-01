class PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[ edit update ]

  def new
  end

  def create
    if user = User.find_by(email_address: params[:email_address])
      PasswordsMailer.reset(user).deliver_later
    end

    redirect_to new_session_path, notice: "Instructions de réinitialisation du mot de passe envoyées (si un utilisateur avec cette adresse e-mail existe)."
  end

  def edit

    PasswordsMailer.reset(current_user).deliver_later
    redirect_to user_path(current_user), notice: "Instructions de réinitialisation du mot de passe envoyées à #{@user.email_address}."
  end

  def update
    if @user.update(params.permit(:password, :password_confirmation))
      redirect_to new_session_path, notice: "Le mot de passe a été réinitialisé."
    else
      redirect_to edit_password_path(params[:token]), alert: "Les mots de passe ne correspondent pas."
    end
  end

  private
    def set_user_by_token
      @user = User.find_by_token_for(:password_reset, params[:token])
      redirect_to new_password_path, alert: "Le lien de réinitialisation du mot de passe est invalide ou a expiré." unless @user
    end
end
