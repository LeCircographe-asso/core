require "ostruct"

module People
  class NewsletterOnlySignupService
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :email, :string
    attribute :first_name, :string, default: "Newsletter"
    attribute :last_name, :string, default: "Subscriber"

    validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    validate :email_uniqueness

    def call
      return failure("Invalid data: #{errors.full_messages.join(', ')}") unless valid?

      ActiveRecord::Base.transaction do
        # Chercher une Person existante par email
        existing_person = Person.find_by(email: email)
        
        if existing_person
          handle_existing_person(existing_person)
        else
          create_newsletter_only_person
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      failure(e.message)
    end

    private

    def handle_existing_person(person)
      if person.newsletter_subscribed
        success(person, "Cette adresse email est déjà inscrite à la newsletter.")
      else
        person.update!(newsletter_subscribed: true)
        success(person, "Vous êtes maintenant inscrit à la newsletter.")
      end
    end

    def create_newsletter_only_person
      # Créer une Person uniquement pour la newsletter
      person = Person.new(
        first_name: first_name,
        last_name: last_name,
        email: email,
        newsletter_subscribed: true
      )
      
      # Skip validation d'adhésion pour newsletter seule
      person.skip_membership_validation = true
      person.save!

      success(person, "Inscription à la newsletter réussie !")
    end

    def email_uniqueness
      return if email.blank?

      # Vérifier l'unicité dans Person
      if Person.where(email: email).exists?
        return # Person existe déjà, on gérera dans handle_existing_person
      end

      # Vérifier s'il existe un User avec le même email mais sans Person liée
      if User.where(email_address: email).where(person_id: nil).exists?
        errors.add(:email, "est déjà utilisé par un compte de connexion existant")
      end
    end

    def success(person, message)
      OpenStruct.new(
        success?: true,
        person: person,
        message: message
      )
    end

    def failure(message)
      OpenStruct.new(
        success?: false,
        errors: [message],
        message: message
      )
    end
  end
end
