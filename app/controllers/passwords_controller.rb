class PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[edit update]

  def new
  end

  def create
    user = User.find_by(email_address: params[:email_address])
    if user
      user.generate_password_reset_token!
      PasswordsMailer.reset(user).deliver_later
    end
    redirect_to new_session_path, notice: "Instructions de réinitialisation envoyées si l'email existe."
  end

  def edit
  end

  def update
    if @user.update(params.permit(:password, :password_confirmation))
      @user.clear_password_reset_token!
      redirect_to new_session_path, notice: "Mot de passe réinitialisé avec succès."
    else
      flash.now[:alert] = "Les mots de passe ne correspondent pas."
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user_by_token
    @user = User.find_by(password_reset_token: params[:token])
    unless @user&.password_reset_token_valid?
      redirect_to new_password_path, alert: "Le lien de réinitialisation est invalide ou expiré."
    end
  end
end
