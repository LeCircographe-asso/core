class UserMailer < ApplicationMailer


  def welcome_by_admin(user, reset_password_url)
    @user = user
    @reset_password_url = reset_password_url
    @url = "https://lecircographe.fr/"
    mail(from: "circographe.mail@gmail.com", to: @user.email_address, subject: "Bienvenue au Circographe ! ")
  end

  def welcome_email(user)
    @user = user
    @url = "https://lecircographe.fr/"
    mail(from: "circographe.mail@gmail.com", to: @user.email_address, subject: "Bienvenue au Circographe ! ")
  end

  def membership_expiration_reminder(user_membership)
    @user = user_membership.user
    @end_date = user_membership.end_date
    @url = "https://lecircographe.fr/"
    mail(from: "circographe.mail@gmail.com", to: @user.email_address, subject: "Votre adhésion arrive à expiration !")
  end

  def contact_email(name, email, message, category, recipient_email)
    @name = name
    @message = message
    @category = category
    @submitted_at = Time.now
    mail(from: "circographe.mail@gmail.com", to: recipient_email, subject: "Nouveau message : #{category.capitalize}", reply_to: email)
  end
end