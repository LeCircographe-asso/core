class ContactsController < ApplicationController
  def create
    @contact = params[:contact]

    if @contact.nil? || @contact[:name].blank? || @contact[:email].blank? || @contact[:message].blank? || @contact[:category].blank?
      flash[:alert] = "Veuillez remplir tous les champs du formulaire."
      return redirect_to page_path("contact")
    end

    recipient_email = case @contact[:category]
    when "technical"
        ENV["CONTACT_EMAIL_TECHNICAL"]
    when "residence"
        ENV["CONTACT_EMAIL_RESIDENCE"]
    when "partnership"
        ENV["CONTACT_EMAIL_PARTNERSHIP"]
    else
        ENV["CONTACT_EMAIL_GENERAL"]
    end

    begin
      UserMailer.contact_email(
        @contact[:name],
        @contact[:email],
        @contact[:message],
        @contact[:category],
        recipient_email
      ).deliver_now

      flash[:notice] = "Votre message a été envoyé avec succès! Nous vous répondrons dans les plus brefs délais."
      redirect_to page_path("contact")
    rescue => e
      Rails.logger.error("Échec d'envoi d'email: #{e.message}")
      flash[:alert] = "Une erreur est survenue lors de l'envoi de votre message. Veuillez réessayer ultérieurement."
      redirect_to page_path("contact")
    end
  end
end
