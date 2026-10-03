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

  # Adressé à la Person (pas au User) : un adhérent n'a pas forcément de compte web.
  def membership_expiration_reminder(membership)
    @person = membership.person
    @end_date = membership.ended_at
    @url = "https://lecircographe.fr/"
    mail(to: @person.email, subject: I18n.t("mailers.user_mailer.membership_expiration_reminder.subject"))
  end

  def contact_email(name, email, message, category, recipient_email)
    @name = name
    @email = email
    @message = message
    @category = category
    @category_label = contact_category_label(category)
    @submitted_at = Time.zone.now
    mail(
      to: recipient_email,
      subject: "#{contact_filter_tag(category)} #{I18n.t("mailers.user_mailer.contact_email.subject", category_label: @category_label)}",
      reply_to: email
    )
  end

  def email_change_verification(user, new_email, code)
    @user = user
    @new_email = new_email
    @code = code
    @ttl_minutes = (User::EMAIL_CHANGE_CODE_TTL / 60).to_i

    mail(
      to: @new_email,
      subject: I18n.t("mailers.user_mailer.email_change_verification.subject")
    )
  end

  private

  # Tag stable et non traduit en tête d'objet : sert de critère aux filtres Gmail
  # (tous les messages arrivent sur la même boîte, le libellé se fait sur ce tag).
  # Ne pas le modifier sans mettre à jour les filtres de la boîte de réception.
  def contact_filter_tag(category)
    "[contact-#{category.to_s.parameterize}]"
  end

  def contact_category_label(category)
    I18n.t(
      "mailers.user_mailer.contact_email.category_labels.#{category}",
      default: category.to_s.tr("_", " ").capitalize
    )
  end
end
