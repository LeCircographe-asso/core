require "ostruct"

module People
  class AccountClaimer
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :email, :string
    # user optionnel pour la revendication

    validates :email, presence: true
    validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }

    def call
      return failure("Invalid data") unless valid?

      # Chercher Person avec cet email SANS User
      candidate = Person.active
        .where(email: email)
        .left_joins(:user)
        .where(users: { id: nil })
        .first

      return failure("Aucune fiche membre trouvée avec cet email") if candidate.nil?

      # Créer AccountClaim
      claim = AccountClaim.create!(
        person: candidate,
        user: nil, # Sera lié après confirmation
        expires_at: 24.hours.from_now
      )

      # Envoyer email confirmation
      AccountClaimMailer.confirmation_email(claim).deliver_later

      success(claim, "Email de confirmation envoyé à #{email}")
    rescue => e
      failure(e.message)
    end

    private

    def success(claim, message)
      OpenStruct.new(success?: true, claim: claim, message: message)
    end

    def failure(message)
      OpenStruct.new(success?: false, errors: [ message ], message: message)
    end
  end
end
