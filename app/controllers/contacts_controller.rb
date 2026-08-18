# frozen_string_literal: true

class ContactsController < ApplicationController
  allow_unauthenticated_access only: :create

  CONTACT_SUBMISSION_KEYS = %i[name email message category].freeze
  LEGACY_CONTACT_CATEGORY_TO_CANONICAL = {
    "residence" => "creative_hosting"
  }.freeze

  def create
    @contact = contact_submission_params

    unless contact_submission_complete?
      respond_with_error(t(".blank_fields"))
      return
    end

    unless @contact[:email].match?(URI::MailTo::EMAIL_REGEXP)
      respond_with_error(t(".invalid_email"))
      return
    end

    category = canonical_contact_category(@contact[:category])
    recipient_email = recipient_email_for(category)

    if recipient_email.blank?
      Rails.logger.error(
        "[ContactsController] Aucune adresse configurée pour category=#{category.inspect} " \
        "— message de #{@contact[:email]} non envoyé"
      )
      respond_with_error(t(".send_error"))
      return
    end

    begin
      UserMailer.contact_email(
        @contact[:name],
        @contact[:email],
        @contact[:message],
        category,
        recipient_email
      ).deliver_later

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("contact_form", partial: "pages/contact/form_inner", locals: { contact: {}, status: :success })
        end
        format.html do
          flash[:notice] = t(".sent_notice")
          redirect_to page_path("contact_us")
        end
      end
    rescue StandardError => e
      Rails.logger.error("Échec d'envoi d'email: #{e.message}")
      respond_with_error(t(".send_error"))
    end
  end

  private

  def canonical_contact_category(raw)
    key = raw.to_s
    LEGACY_CONTACT_CATEGORY_TO_CANONICAL.fetch(key, key)
  end

  # Retombe toujours sur CONTACT_EMAIL_GENERAL si l'adresse spécifique à la
  # catégorie n'est pas configurée, pour ne jamais perdre un message silencieusement
  # (avant ce correctif : un ENV manquant enqueue un job de mail avec to: nil,
  # qui échoue en arrière-plan sans que le visiteur ni l'admin ne le sachent).
  def recipient_email_for(category)
    specific =
      case category
      when "technical"
        ENV.fetch("CONTACT_EMAIL_TECHNICAL", nil)
      when "creative_hosting"
        ENV.fetch("CONTACT_EMAIL_CREATIVE_HOSTING", nil) || ENV.fetch("CONTACT_EMAIL_RESIDENCE", nil)
      when "partnership"
        ENV.fetch("CONTACT_EMAIL_PARTNERSHIP", nil)
      end

    specific.presence || ENV.fetch("CONTACT_EMAIL_GENERAL", nil)
  end

  # Formulaire public : champs à la racine (`name`, `email`, …), pas `contact[...]`.
  # Toujours inclure les clés requises : `permit` seul omet les paramètres absents, ce qui faisait
  # passer des requêtes incomplètes jusqu’au mailer.
  def contact_submission_params
    permitted = params.permit(*CONTACT_SUBMISSION_KEYS).to_h.symbolize_keys
    CONTACT_SUBMISSION_KEYS.index_with { |key| permitted[key] }
  end

  def contact_submission_complete?
    CONTACT_SUBMISSION_KEYS.all? { |key| @contact[key].present? }
  end

  def respond_with_error(message)
    respond_to do |format|
      format.turbo_stream do
        flash.now[:alert] = message
        # Le formulaire seul (turbo_stream.update("contact_form", ...)) ne suffit pas :
        # flash.now n'apparaît nulle part tant que le frame #flash n'est pas aussi mis à
        # jour dans la même réponse — sinon le visiteur ne voit jamais le message d'erreur.
        render turbo_stream: [
          turbo_stream.update("contact_form", partial: "pages/contact/form_inner", locals: { contact: @contact, status: :error }),
          turbo_stream.replace(ProfileSectionDomIds::FLASH_FRAME, partial: "shared/flash")
        ]
      end
      format.html do
        flash[:alert] = message
        redirect_to page_path("contact_us")
      end
    end
  end
end
