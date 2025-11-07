module UserManagement
  class UserCreator
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :email, :string
    attribute :password, :string
    attribute :password_confirmation, :string
    attribute :role, :string
    attribute :person_id, :integer
    attribute :created_by_id, :integer

    validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :password, presence: true, length: { minimum: 6 }
    validates :password_confirmation, presence: true
    validates :role, presence: true, inclusion: { in: %w[volunteer admin super_admin] }
    validates :person_id, presence: true
    validates :created_by_id, presence: true

    validate :passwords_match
    validate :person_exists
    validate :person_has_no_user_account

    def call
      return failure("Invalid user data") unless valid?

      begin
        ActiveRecord::Base.transaction do
          # Find the person and creator
          person = Person.find(person_id)
          created_by = User.find(created_by_id)

          # Create user account
          user = User.create!(
            email: email,
            password: password,
            password_confirmation: password_confirmation,
            role: role,
            person: person,
            created_by: created_by
          )

          # Update person with user reference
          person.update!(user: user)

          success(user: user)
        end
      rescue ActiveRecord::RecordNotFound => e
        failure("Person or User not found: #{e.message}")
      rescue ActiveRecord::RecordInvalid => e
        failure("Validation error: #{e.message}")
      rescue => e
        failure("Unexpected error: #{e.message}")
      end
    end

    private

    def passwords_match
      return unless password.present? && password_confirmation.present?

      if password != password_confirmation
        errors.add(:password_confirmation, "doesn't match Password")
      end
    end

    def person_exists
      return unless person_id.present?

      unless Person.exists?(person_id)
        errors.add(:person_id, "Person not found")
      end
    end

    def person_has_no_user_account
      return unless person_id.present?

      person = Person.find_by(id: person_id)
      if person&.user.present?
        errors.add(:person_id, "Person already has a user account")
      end
    end

    def success(data = {})
      OpenStruct.new(success?: true, **data)
    end

    def failure(message)
      OpenStruct.new(success?: false, message: message)
    end
  end
end
