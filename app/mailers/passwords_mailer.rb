class PasswordsMailer < ApplicationMailer
  def reset_password(user)
    @user = user
    @url = edit_password_reset_url(token: @user.password_reset_token)
    mail(to: @user.email_address, subject: 'Réinitialisation de votre mot de passe')
  end


  def reset_password_by_admin(user)
    @user = user
    @url = edit_password_reset_url(token: @user.password_reset_token)
    mail(to: @user.email_address, subject: 'Réinitialisation de votre mot de passe demandée par un administrateur')
  end
end
