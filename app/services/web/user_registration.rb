require "ostruct"

module Web
  class UserRegistration
    include ActiveModel::Model
    include ActiveModel::Attributes

    # Attributs pour la création de personne
    attribute :first_name, :string
    attribute :last_name, :string
    attribute :email, :string
    attribute :newsletter_subscribed, :boolean, default: false

    # Attributs pour la création de compte utilisateur
    attribute :user_email, :string
    attribute :user_password, :string
    attribute :user_system_role, :string, default: "web_visitor"
    attribute :cgu, :string
    attribute :privacy_policy, :string

    # Validations
    validates :first_name, presence: true
    validates :last_name, presence: true
    validates :email, presence: true
    validates :user_email, presence: true
    validates :user_password, presence: true
    validates :user_system_role, inclusion: { in: %w[super_admin admin volunteer web_visitor] }
    validates :cgu, acceptance: { message: "Vous devez accepter les CGU pour continuer." }
    validates :privacy_policy, acceptance: { message: "Vous devez accepter la politique de confidentialité pour continuer." }
    validate :email_uniqueness
    validate :user_email_uniqueness

    def call
      return failure("Invalid data: #{errors.full_messages.join(', ')}") unless valid?

      ActiveRecord::Base.transaction do
        # 1. Créer ou trouver la Person
        person_result = create_or_find_person
        return failure(person_result.errors.join(", ")) unless person_result.success?

        person = person_result.person

        # 2. Créer le compte utilisateur
        user_result = create_user_account(person)
        return failure(user_result.errors.join(", ")) unless user_result.success?

        success(person, user_result.user)
      end
    rescue ActiveRecord::RecordInvalid => e
      failure(e.message)
    end

    private

    def create_or_find_person
      # Chercher une Person existante par email
      existing_person = Person.find_by(email: email)

      if existing_person
        # Mettre à jour la Person existante
        existing_person.update!(
          first_name: first_name,
          last_name: last_name,
          newsletter_subscribed: newsletter_subscribed
        )
        success(existing_person, "Person updated")
      else
        # Créer une nouvelle Person
        People::PersonCreator.new(
          first_name: first_name,
          last_name: last_name,
          email: email,
          newsletter_subscribed: newsletter_subscribed
        ).call
      end
    end

    def create_user_account(person)
      # Vérifier si la Person a déjà un User
      if person.user.present?
        # Mettre à jour le User existant
        person.user.update!(
          email_address: user_email,
          password: user_password,
          password_confirmation: user_password,
          system_role: user_system_role
        )
        success(person.user, "User account updated")
      else
        # Créer un nouveau User
        People::UserAccountCreator.new(
          person: person,
          user_email: user_email,
          user_password: user_password,
          user_system_role: user_system_role,
          created_by_admin: false, # Créé par l'utilisateur lui-même
          cgu: cgu,
          privacy_policy: privacy_policy
        ).call
      end
    end

    def email_uniqueness
      return if email.blank?

      # Vérifier l'unicité dans Person
      if Person.where(email: email).where.not(id: nil).exists?
        errors.add(:email, "has already been taken")
      end

      # Vérifier s'il existe un User avec le même email mais sans Person liée
      # (cas où User existe mais Person n'existe pas encore)
      if User.where(email_address: email).where(person_id: nil).exists?
        errors.add(:email, "is already used by an existing user account")
      end
    end

    def user_email_uniqueness
      return if user_email.blank?

      # Vérifier l'unicité dans User
      if User.where(email_address: user_email).where.not(person_id: nil).exists?
        errors.add(:user_email, "has already been taken")
      end

      # Vérifier s'il existe une Person avec le même email
      # (pour éviter les conflits entre Person.email et User.email_address)
      if Person.where(email: user_email).where.not(id: nil).exists?
        errors.add(:user_email, "is already used as newsletter email")
      end
    end

    def success(person, user, message = "Web user registration successful")
      OpenStruct.new(
        success?: true,
        person: person,
        user: user,
        message: message
      )
    end

    def failure(message)
      OpenStruct.new(
        success?: false,
        errors: [ message ],
        message: message
      )
    end
  end
end
