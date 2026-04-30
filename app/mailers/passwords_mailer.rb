# frozen_string_literal: true

class PasswordsMailer < ApplicationMailer
  def reset(user)
    @user = user
    mail subject: "Réinitialisez votre mot de passe", to: user.email_address
  end
end
