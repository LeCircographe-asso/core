class RegistrationsController < ApplicationController
  allow_unauthenticated_access

  def new
    if authenticated?
      redirect_to root_path
    end
    @user = User.new
  end

  def create
    email = params[:email_address]
    pwd = params[:password]
    pwdc = params[:password_confirmation]
    @user = User.new(email_address: email, password: pwd, password_confirmation: pwdc)
    if @user.save
      start_new_session_for @user
      redirect_to root_path, notice: 'Inscription réussie !'
    else
      render :new, status: :unprocessable_entity 
    end
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end