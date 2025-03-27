class PasswordsMailer < ApplicationMailer
  def reset_password(user)
    @user = user
    mail subject: "Reset your password", to: user.email_address
  end
end
