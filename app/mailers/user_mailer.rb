# frozen_string_literal: true

class UserMailer < ApplicationMailer
  def welcome_by_admin(user, reset_password_url)
    @user = user
    @reset_password_url = reset_password_url
    @url = "https://lecircographe.fr/"
    set_unsubscribe_url
    mail(to: @user.email_address, subject: I18n.t("mailers.user_mailer.welcome_by_admin.subject"))
  end

  def welcome_email(user)
    @user = user
    @url = "https://lecircographe.fr/"
    set_unsubscribe_url
    mail(to: @user.email_address, subject: I18n.t("mailers.user_mailer.welcome_email.subject"))
  end

  def membership_expiration_reminder(user_membership)
    @user = user_membership.user
    @end_date = user_membership.end_date
    @url = "https://lecircographe.fr/"
    mail(to: @user.email_address, subject: I18n.t("mailers.user_mailer.membership_expiration_reminder.subject"))
  end

  def contact_email(name, email, message, category, recipient_email)
    @name = name
    @message = message
    @category = category
    @submitted_at = Time.zone.now
    mail(to: recipient_email, subject: "Nouveau message : #{category.capitalize}", reply_to: email)
  end
end
