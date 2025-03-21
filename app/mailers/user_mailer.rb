class UserMailer < ApplicationMailer
  default from: "no-reply@lecircographe.fr"

  def welcome_email(user)
    @user = user
    @url = "http://lecircographe.fr"
    mail(to: @user.email_address, subject: "Bienvenue sur Le Circographe !")
  end

  def welcome_by_admin(user)
    @user = user
    mail(to: @user.email_address, subject: "Bienvenue à bord !")
  end

  def newsletter_subscription(user)
    @user = user
    mail(to: @user.email_address, subject: "Bienvenue à notre newsletter ! 🎉")
  end


  def contact_email(name, email, message, category, recipient_email)
    @name = name
    @message = message
    @category = category
    @submitted_at = Time.now
    mail(to: recipient_email, subject: "Nouveau message : #{category.capitalize}", reply_to: email)
  end
end
