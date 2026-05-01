# frozen_string_literal: true

class ContactsController < ApplicationController
  allow_unauthenticated_access only: :create

  CONTACT_SUBMISSION_KEYS = %i[name email message category].freeze

  def create
    @contact = contact_submission_params

    unless contact_submission_complete?
      respond_with_error(t(".blank_fields"))
      return
    end

    recipient_email = case @contact[:category]
    when "technical"
                        ENV.fetch("CONTACT_EMAIL_TECHNICAL", nil)
    when "residence"
                        ENV.fetch("CONTACT_EMAIL_RESIDENCE", nil)
    when "partnership"
                        ENV.fetch("CONTACT_EMAIL_PARTNERSHIP", nil)
    else
                        ENV.fetch("CONTACT_EMAIL_GENERAL", nil)
    end

    begin
      UserMailer.contact_email(
        @contact[:name],
        @contact[:email],
        @contact[:message],
        @contact[:category],
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
        render turbo_stream: turbo_stream.update("contact_form", partial: "pages/contact/form_inner", locals: { contact: @contact, status: :error })
      end
      format.html do
        flash[:alert] = message
        redirect_to page_path("contact_us")
      end
    end
  end
end
