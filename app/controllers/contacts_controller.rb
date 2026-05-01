# frozen_string_literal: true

class ContactsController < ApplicationController
  allow_unauthenticated_access only: :create

  def create
    @contact = contact_submission_params

    if @contact.values.any?(&:blank?)
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
  def contact_submission_params
    params.permit(:name, :email, :message, :category).to_h.symbolize_keys
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
