require "ostruct"

module People
  class AccountMerger
    include ActiveModel::Model
    include ActiveModel::Attributes

    attr_accessor :person
    attribute :user_email, :string
    attribute :user_password, :string
    attribute :user_system_role, :string, default: "web_visitor"

    validates :person, presence: true
    validates :user_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :user_password, presence: true
    validates :user_system_role, inclusion: { in: %w[super_admin admin volunteer web_visitor] }
    validate :user_email_different_from_person_email
    validate :user_email_uniqueness

    def call
      return failure("Invalid data: #{errors.full_messages.join(', ')}") unless valid?

      ActiveRecord::Base.transaction do
        # Vérifier si la Person a déjà un User
        if person.user.present?
          update_existing_user
        else
          create_new_user_for_person
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      failure(e.message)
    end

    private

    def update_existing_user
      existing_user = person.user
      
      # Mettre à jour le User existant avec le nouvel email
      existing_user.update!(
        email_address: user_email,
        password: user_password,
        password_confirmation: user_password,
        system_role: user_system_role
      )

      success(existing_user, "Compte utilisateur mis à jour pour #{person.full_name}")
    end

    def create_new_user_for_person
      # Créer un nouveau User lié à la Person existante
      user = User.create!(
        person: person,
        email_address: user_email,
        password: user_password,
        password_confirmation: user_password,
        system_role: user_system_role,
        created_by_admin: true
      )

      success(user, "Compte utilisateur créé pour #{person.full_name}")
    end

    def user_email_different_from_person_email
      return if user_email.blank? || person&.email.blank?

      if user_email.downcase == person.email.downcase
        errors.add(:user_email, "doit être différent de l'email de newsletter (#{person.email})")
      end
    end

    def user_email_uniqueness
      return if user_email.blank?

      # Vérifier l'unicité dans User
      existing_user = User.find_by(email_address: user_email)
      
      if existing_user && existing_user != person&.user
        if existing_user.person.present?
          errors.add(:user_email, "est déjà utilisé par #{existing_user.person.full_name}")
        else
          errors.add(:user_email, "est déjà utilisé par un compte existant")
        end
      end

      # Vérifier s'il existe une Person avec le même email
      if Person.where(email: user_email).where.not(id: person&.id).exists?
        conflicting_person = Person.find_by(email: user_email)
        errors.add(:user_email, "est déjà utilisé comme email de newsletter par #{conflicting_person.full_name}")
      end
    end

    def success(user, message)
      OpenStruct.new(
        success?: true,
        user: user,
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
