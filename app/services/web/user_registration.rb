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
    attribute :user_system_role, :string, default: "web_visitor"
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
    validates :cgu, acceptance: { message: "Vous devez accepter les CGU pour continuer." }, allow_nil: false
    validates :privacy_policy, acceptance: { message: "Vous devez accepter la politique de confidentialité pour continuer." }, allow_nil: false
    validate :email_uniqueness
    validate :user_email_uniqueness
    validate :password_confirmation_matches

    def call
      return failure("Invalid data: #{errors.full_messages.join(', ')}") unless valid?

      ActiveRecord::Base.transaction do
        # 1. Créer ou trouver la Person
        person_result = create_or_find_person
        return failure(person_result.errors.join(", ")) unless person_result.success?

        person = person_result.person

        # 1.5. Créer NewsletterSubscriber si demandé
        if newsletter_subscribed == true
          create_newsletter_subscriber(person)
        end

        # 2. Créer le compte utilisateur
        user_result = create_user_account(person)
        return failure(user_result.errors.join(", ")) unless user_result.success?

        success(person: person, user: user_result.user, message: "Web user registration successful")
      end
    rescue ActiveRecord::RecordInvalid => e
      failure(e.message)
    end

    private

    def create_or_find_person
      # 1. Chercher si Person existe avec cet email
      existing_person = Person.active.find_by(email: email) if email.present?

      if existing_person
        # Person existe → Bloquer et proposer revendication
        Rails.logger.warn("[WEB_REGISTRATION] BLOCKED: Email #{email} existe sur Person #{existing_person.id}")

        if existing_person.user.present?
          # Person a déjà un User → Mot de passe oublié
          return failure("Cette adresse email est déjà utilisée. Utilisez 'Mot de passe oublié' pour récupérer votre compte.")
        else
          # Person sans User → Revendication
          return failure("Cette adresse email est associée à une fiche adhérent. Utilisez 'Récupérer mon compte' pour la lier à votre espace web.")
        end
      end

      # 2. Supprimer la recherche par nom+prénom (trop permissive)
      # SUPPRIMÉ : candidates = Person.active.where(...)

      # 3. Créer nouvelle Person
      # newsletter_subscribed removed - handled by create_newsletter_subscriber
      Rails.logger.info("[WEB_REGISTRATION] Création nouvelle Person pour #{email}")
      PersonManagement::PersonCreator.new(
        first_name: first_name,
        last_name: last_name,
        email: email
      ).call
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
        success(person: person.user.person, user: person.user, message: "User account updated")
      else
        # Créer un nouveau User
        UserManagement::AccountCreator.new(
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

    def create_newsletter_subscriber(person)
      # Si NewsletterSubscriber existe déjà (inscription footer), le lier à cette Person
      subscriber = NewsletterSubscriber.find_by(email: person.email)
      
      if subscriber
        # Link existing orphaned subscriber to new Person
        subscriber.update!(person: person, subscribed: true)
      else
        # Create new NewsletterSubscriber for this Person
        NewsletterSubscriber.create!(
          email: person.email,
          person: person,
          source: 'web',
          subscribed: true
        )
      end
    end

    def email_uniqueness
      return if email.blank?

      # Vérifier si une Person avec cet email existe
      existing_person = Person.active.find_by(email: email)

      if existing_person
        if existing_person.user.present?
          # Person a déjà un compte web → erreur
          errors.add(:email, "Cette adresse email est déjà utilisée. Veuillez utiliser une autre adresse ou vous connecter.")
        else
          # Person existe mais pas de compte web → OK, on va la récupérer
          # Pas d'erreur, on va lier le compte web à cette Person
        end
      end

      # Vérifier s'il existe un User avec le même email mais sans Person liée
      # (cas où User existe mais Person n'existe pas encore)
      if User.where(email_address: email).where(person_id: nil).exists?
        errors.add(:email, "is already used by an existing user account")
      end
    end

    def user_email_uniqueness
      return if user_email.blank?

      # Vérifier l'unicité dans User (sauf si c'est le même email que email)
      if user_email != email && User.where(email_address: user_email).where.not(person_id: nil).exists?
        errors.add(:user_email, "has already been taken")
      end

      # Vérifier s'il existe une Person avec le même email
      existing_person = Person.active.find_by(email: user_email)
      if existing_person
        if existing_person.user.present?
          # Person a déjà un compte web → erreur
          errors.add(:user_email, "is already used as newsletter email")
        else
          # Person existe mais pas de compte web → OK, on va la récupérer
          # Pas d'erreur
        end
      end
    end

    def password_confirmation_matches
      return if user_password.blank? || user_password_confirmation.blank?
      
      unless user_password == user_password_confirmation
        errors.add(:user_password_confirmation, "ne correspond pas au mot de passe")
      end
    end

    # success et failure hérités de BaseService
  end
end
