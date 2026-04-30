# frozen_string_literal: true

class PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[edit update]

  def new; end

  def edit; end

  def create
    if (user = User.find_by(email_address: params[:email_address]))
      PasswordsMailer.reset(user).deliver_later
    end

    redirect_to new_session_path, notice: t(".reset_instructions_sent_generic")
  end

  def update
    if @user.update(params.permit(:password, :password_confirmation))
      redirect_to new_session_path, notice: t(".password_reset_success")
    else
      render :edit, status: :unprocessable_content
    end
  end

  def request_reset
    if authenticated?
      PasswordsMailer.reset(current_user).deliver_later
      redirect_to user_path(current_user), notice: t(".sent_to_email_notice", email: current_user.email_address)
    else
      redirect_to new_session_path, alert: t(".must_be_signed_in_alert")
    end
  end

  private

  def set_user_by_token
    @user = User.find_by_token_for(:password_reset, params[:token])
    redirect_to new_password_path, alert: I18n.t("passwords.invalid_token_alert") unless @user
  end
end
