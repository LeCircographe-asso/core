module UserManagement
  class UserCreator < BaseService
    attribute :email, :string
    attribute :password, :string
    attribute :password_confirmation, :string
    attribute :role, :string
    attribute :person_id, :integer
    attribute :created_by_id, :integer

    validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :password, presence: true, length: { minimum: 6 }
    validates :password_confirmation, presence: true
    validates :role, presence: true, inclusion: { in: %w[volunteer admin super_admin web_visitor] }
    validates :person_id, presence: true
    validates :created_by_id, presence: true

    validate :passwords_match
    validate :person_exists
    validate :person_has_no_user_account

    def call
      return failure('Invalid user data') unless valid?

      person = Person.find(person_id)
      created_by = User.find(created_by_id)
      validate_creator_permissions!(created_by)

      return failure('Insufficient permissions to create accounts') unless creator_can_manage_accounts?(created_by)

      result = People::UserAccountCreator.new(
        person: person,
        email_address: email,
        system_role: role,
        password: password,
        created_by_admin: created_by.admin? || created_by.super_admin?,
        cgu: true,
        privacy_policy: true
      ).call

      if result.success?
        success(user: result.user, message: result.message)
      else
        failure(result.message, errors: result.errors)
      end
    rescue ActiveRecord::RecordNotFound => e
      failure("Person or User not found: #{e.message}")
    rescue StandardError => e
      Rails.logger.error("[UserManagement::UserCreator] #{e.class}: #{e.message}\n#{e.backtrace.take(5).join("\n")}")
      failure("Unexpected error: #{e.message}")
    end

    private

    def passwords_match
      return unless password.present? && password_confirmation.present?

      return unless password != password_confirmation

      errors.add(:password_confirmation, "doesn't match Password")
    end

    def person_exists
      return unless person_id.present?

      return if Person.exists?(person_id)

      errors.add(:person_id, 'Person not found')
    end

    def person_has_no_user_account
      return unless person_id.present?

      person = Person.find_by(id: person_id)
      return unless person&.user.present?

      errors.add(:person_id, 'Person already has a user account')
    end

    def validate_creator_permissions!(created_by)
      return if created_by.super_admin? || created_by.admin?

      errors.add(:created_by_id, 'User does not have permissions to create accounts')
      raise ActiveRecord::RecordInvalid.new(created_by)
    end

    def creator_can_manage_accounts?(created_by)
      created_by.super_admin? || created_by.admin?
    end

    # success et failure hérités de BaseService
  end
end
