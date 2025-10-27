require "ostruct"

module People
  class UserAccountCreator
    include ActiveModel::Model
    include ActiveModel::Attributes

    attr_accessor :person
    attribute :user_email, :string
    attribute :user_password, :string
    attribute :user_system_role, :string, default: "web_visitor"
    attribute :created_by_admin, :boolean, default: true

    validates :person, presence: true
    validates :user_email, presence: true
    validates :user_password, presence: true
    validates :user_system_role, inclusion: { in: %w[super_admin admin volunteer web_visitor] }
    validate :user_email_uniqueness
    validate :person_not_already_has_user

    def call
      return failure("Invalid data") unless valid?

      ActiveRecord::Base.transaction do
        # Vérifier si la Person a déjà un User
        if person.user.present?
          update_existing_user
        else
          create_new_user
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      failure(e.message)
    end

    private

    def update_existing_user
      existing_user = person.user

      # Mettre à jour le User existant
      existing_user.update!(
        email_address: user_email,
        password: user_password,
        password_confirmation: user_password,
        system_role: user_system_role
      )

      success(existing_user, "User account updated successfully for #{person.full_name}")
    end

    def create_new_user
      # Créer un nouveau User lié à la Person
      user = User.create!(
        person: person,
        email_address: user_email,
        password: user_password,
        password_confirmation: user_password,
        system_role: user_system_role,
        created_by_admin: created_by_admin
      )

      success(user, "User account created successfully for #{person.full_name}")
    end

    def user_email_uniqueness
      return if user_email.blank?

      # Vérifier l'unicité dans User
      existing_user = User.find_by(email_address: user_email)

      if existing_user && existing_user != person&.user
        # Si l'email existe déjà sur un autre User
        if existing_user.person.present?
          errors.add(:user_email, "is already used by #{existing_user.person.full_name}")
        else
          errors.add(:user_email, "is already used by an existing user account")
        end
      end

      # Vérifier s'il existe une Person avec le même email
      # (pour éviter les conflits entre Person.email et User.email_address)
      if Person.where(email: user_email).where.not(id: person&.id).exists?
        conflicting_person = Person.find_by(email: user_email)
        errors.add(:user_email, "is already used as newsletter email by #{conflicting_person.full_name}")
      end
    end

    def person_not_already_has_user
      nil unless person&.user.present?

      # Si la Person a déjà un User, on peut quand même mettre à jour
      # Cette validation est juste informative
      # Le service gérera la mise à jour automatiquement
    end

    def success(user, message)
      OpenStruct.new(
        success?: true,
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
