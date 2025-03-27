class UserMailer < ApplicationMailer
  default from: "no-reply@lecircographe.fr"

  def welcome_by_admin(user, reset_password_url)
    @user = user
    @reset_password_url = reset_password_url
    @url = "https://lecircographe.fr"
    mail(to: @user.email_address, subject: "Bienvenue au Circographe ! 🎉")
  end

  def welcome_email(user)
    @user = user
    @url = "https://lecircographe.fr"
    mail(to: @user.email_address, subject: "Bienvenue au Circographe ! 🎉")
  end

  def contact_email(name, email, message, category, recipient_email)
    @name = name
    @message = message
    @category = category
    @submitted_at = Time.now
    mail(to: recipient_email, subject: "Nouveau message : #{category.capitalize}", reply_to: email)
  end
end
