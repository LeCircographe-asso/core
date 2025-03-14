class UserMailer < ApplicationMailer
  default from: "no-reply@lecircographe.fr"

  def welcome_email(user)
    @user = user
    @url = "http://lecircographe.fr"

    mail(to: @user.email_address, subject: "Bienvenue au circographe !")
  end
end
