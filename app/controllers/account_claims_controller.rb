class AccountClaimsController < ApplicationController
  before_action :require_authentication, only: [ :create ]

  def new
    @claim = AccountClaim.new
  end

  def create
    begin
      # Chercher une Person existante par email
      person = Person.find_by(email: params[:email])

      if person&.can_be_claimed_by?(params[:email])
        # Créer la demande de réclamation
        claim = AccountClaim.create!(
          person: person,
          user: Current.user,
          confirmation_token: SecureRandom.urlsafe_base64(32),
          expires_at: 24.hours.from_now
        )

        # Envoyer l'email de confirmation
        # TODO: Implémenter l'envoi d'email

        redirect_to root_path, notice: "Demande de réclamation envoyée. Vérifiez vos emails."
      else
        redirect_to root_path, alert: "Aucun compte trouvé avec cet email ou déjà lié."
      end
    rescue => e
      redirect_to root_path, alert: "Erreur: #{e.message}"
    end
  end

  def confirm
    claim = AccountClaim.find_by!(confirmation_token: params[:token])

    if claim.expired?
      redirect_to root_path, alert: "Lien expiré (24h)"
      return
    end

    begin
      # Fusionner les données Person admin → User actuel
      admin_person = claim.person
      user_person = claim.user.person || claim.user.build_person

      # Copier les données de l'admin vers l'utilisateur
      user_person.update!(
        first_name: admin_person.first_name,
        last_name: admin_person.last_name,
        email: admin_person.email,
        phone: admin_person.phone,
        address: admin_person.address,
        zip_code: admin_person.zip_code,
        town: admin_person.town,
        country: admin_person.country,
        birth_date: admin_person.birth_date,
        emergency_contact_name: admin_person.emergency_contact_name,
        emergency_contact_phone: admin_person.emergency_contact_phone,
        notes: admin_person.notes,
        occupation: admin_person.occupation,
        specialty: admin_person.specialty,
        image_rights: admin_person.image_rights,
        get_involved: admin_person.get_involved,
        newsletter_subscribed: admin_person.newsletter_subscribed,
        dyslexic_font: admin_person.dyslexic_font
      )

      # Supprimer l'ancienne Person admin
      admin_person.destroy!

      # Marquer la réclamation comme confirmée
      claim.update!(status: :confirmed)

      redirect_to user_path(claim.user), notice: "✅ Compte revendiqué ! Votre historique est maintenant disponible."
    rescue => e
      redirect_to root_path, alert: "Erreur lors de la réclamation: #{e.message}"
    end
  end
end
