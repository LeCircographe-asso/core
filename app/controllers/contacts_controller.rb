# frozen_string_literal: true

class ContactsController < ApplicationController
  def create
    @contact = params.expect(contact: %i[name email message category])

    if @contact.values.any?(&:blank?)
      respond_with_error("Veuillez remplir tous les champs du formulaire.")
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
          flash.now[:notice] = "Votre message a été envoyé avec succès ! Nous revenons vers vous rapidement."
          render turbo_stream: turbo_stream.update("contact_form", partial: "pages/contact/form", locals: { contact: {}, status: :success })
        end
        format.html do
          flash[:notice] = "Votre message a été envoyé avec succès ! Nous revenons vers vous rapidement."
          redirect_to page_path("contact_us")
        end
      end
    rescue StandardError => e
      Rails.logger.error("Échec d'envoi d'email: #{e.message}")
      respond_with_error("Une erreur est survenue lors de l'envoi. Réessaie dans quelques instants.")
    end
  end

  private

  def respond_with_error(message)
    respond_to do |format|
      format.turbo_stream do
        flash.now[:alert] = message
        render turbo_stream: turbo_stream.update("contact_form", partial: "pages/contact/form", locals: { contact: @contact, status: :error })
      end
      format.html do
        flash[:alert] = message
        redirect_to page_path("contact_us")
      end
    end
  end
end
