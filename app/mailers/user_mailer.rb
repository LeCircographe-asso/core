class UserMailer < ApplicationMailer
  default from: "no-reply@lecircographe.fr"

  def welcome_email(user)
    @user = user
    @url = "http://lecircographe.fr"

    mail(to: @user.email_address, subject: "Bienvenue au circographe !")
  end

  def contact_email(name, email, message, category, recipient_email)
    @name = name
    @email = email
    @message = message
    @category = category
    @submitted_at = Time.now

    mail(
      to: recipient_email,
      subject: "Nouveau message de contact - #{category.capitalize}",
      reply_to: email
    )
  end
end
