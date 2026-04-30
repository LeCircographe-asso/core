# frozen_string_literal: true

module AccountClaimManagement
  class AccountClaimCreator < BaseService
    attribute :email, :string
    attribute :user_id, :integer

    validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :user_id, presence: true

    def call
      return failure("Invalid data: #{errors.full_messages.join(', ')}") unless valid?

      begin
        user = User.find(user_id)

        # Chercher une Person existante par email
        person = Person.find_by(email: email)

        return failure('Aucun compte trouvé avec cet email ou déjà lié') unless person&.can_be_claimed_by?(email)

        # Créer la demande de réclamation
        claim = AccountClaim.create!(
          person: person,
          user: user,
          confirmation_token: SecureRandom.urlsafe_base64(32),
          expires_at: 24.hours.from_now,
          status: :pending
        )

        # Instrumentation pour audit
        ActiveSupport::Notifications.instrument(
          'account_claim.created',
          account_claim_id: claim.id,
          person_id: person.id,
          user_id: user_id,
          email: email
        )

        # TODO: Envoyer l'email de confirmation
        # AccountClaimMailer.confirmation_email(claim).deliver_later

        success(claim: claim, message: 'Demande de réclamation créée avec succès')
      rescue ActiveRecord::RecordNotFound => e
        failure("User not found: #{e.message}")
      rescue StandardError => e
        Rails.logger.error "[AccountClaimCreator] Error: #{e.message}"
        failure("Error creating account claim: #{e.message}")
      end
    end

    # success et failure hérités de BaseService
  end
end
