# frozen_string_literal: true

module Web
  class UserRegistration < BaseService
    # Attributs pour la création de personne
    attribute :first_name, :string
    attribute :last_name, :string
    attribute :email, :string
    attribute :newsletter_subscribed, :boolean, default: false

    # Attributs pour la création de compte utilisateur
    attribute :user_email, :string
    attribute :user_password, :string
    attribute :user_password_confirmation, :string
    attribute :user_system_role, :string, default: 'web_visitor'
    attribute :cgu, :string
    attribute :privacy_policy, :string

    # Validations
    validates :first_name, presence: true
    validates :last_name, presence: true
    validates :email, presence: true
    validates :user_email, presence: true
    validates :user_password, presence: true, length: { minimum: 6 }
    validates :user_password_confirmation, presence: true
    validates :user_system_role, inclusion: { in: %w[super_admin admin volunteer web_visitor] }
    validates :cgu, acceptance: { message: 'Vous devez accepter les CGU pour continuer.' }, allow_nil: false
    validates :privacy_policy, acceptance: { message: 'Vous devez accepter la politique de confidentialité pour continuer.' }, allow_nil: false
    validate :email_uniqueness
    validate :user_email_uniqueness
    validate :password_confirmation_matches

    def call
      return failure("Invalid data: #{errors.full_messages.join(', ')}") unless valid?

      existing_person = Person.active.find_by(email: email)

      if existing_person
        Rails.logger.warn("[WEB_REGISTRATION] BLOCKED: Email #{email} existe sur Person #{existing_person.id}")

        return failure("Cette adresse email est déjà utilisée. Utilisez 'Mot de passe oublié' pour récupérer votre compte.") if existing_person.user.present?

        return failure("Cette adresse email est associée à une fiche adhérent. Utilisez 'Récupérer mon compte' pour la lier à votre espace web.")

      end

      register_result = People::Register.new(
        person_params: {
          first_name: first_name,
          last_name: last_name,
          email: email
        },
        newsletter_subscribed: newsletter_subscribed,
        newsletter_source: 'web',
        create_user_account: true,
        user_params: {
          email_address: user_email,
          password: user_password,
          system_role: user_system_role,
          created_by_admin: false,
          cgu: cgu,
          privacy_policy: privacy_policy
        },
        create_membership: false
      ).call

      if register_result.success?
        success(person: register_result.person, user: register_result.user, message: 'Web user registration successful')
      else
        failure(register_result.errors.join(', '))
      end
    rescue ActiveRecord::RecordInvalid => e
      failure(e.message)
    end

    private

    def email_uniqueness
      return if email.blank?

      # Vérifier si une Person avec cet email existe
      existing_person = Person.active.find_by(email: email)

      if existing_person
        if existing_person.user.present?
          # Person a déjà un compte web → erreur
          errors.add(:email, 'Cette adresse email est déjà utilisée. Veuillez utiliser une autre adresse ou vous connecter.')
        else
          # Person existe mais pas de compte web → OK, on va la récupérer
          # Pas d'erreur, on va lier le compte web à cette Person
        end
      end

      # Vérifier s'il existe un User avec le même email mais sans Person liée
      # (cas où User existe mais Person n'existe pas encore)
      return unless User.where(email_address: email).exists?(person_id: nil)

      errors.add(:email, 'is already used by an existing user account')
    end

    def user_email_uniqueness
      return if user_email.blank?

      # Vérifier l'unicité dans User (sauf si c'est le même email que email)
      errors.add(:user_email, 'has already been taken') if user_email != email && User.where(email_address: user_email).where.not(person_id: nil).exists?

      # Vérifier s'il existe une Person avec le même email
      existing_person = Person.active.find_by(email: user_email)
      return unless existing_person

      if existing_person.user.present?
        # Person a déjà un compte web → erreur
        errors.add(:user_email, 'is already used as newsletter email')
      else
        # Person existe mais pas de compte web → OK, on va la récupérer
        # Pas d'erreur
      end
    end

    def password_confirmation_matches
      return if user_password.blank? || user_password_confirmation.blank?

      return if user_password == user_password_confirmation

      errors.add(:user_password_confirmation, 'ne correspond pas au mot de passe')
    end

    # success et failure hérités de BaseService
  end
end
