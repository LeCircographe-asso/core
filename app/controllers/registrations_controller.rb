class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  def new
    if authenticated?
      redirect_to root_path
    end
    @user = User.new(email_address: session[:newsletter_email])
  end

  def create
    @user = User.new(user_params)
    if @user.save
      # UserMailer.welcome_email(@user).deliver_now
      # redirect_to @user, notice: "Utilisateur créé avec succès."
      start_new_session_for @user
      redirect_to root_path, notice: "Inscription réussie !"
    else
      p @user.errors.full_messages
      flash.now[:alert] = @user.errors.full_messages.join(", ")
    render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation, :cgu, :privacy_policy, :newsletter_subscribed)
  end
end
