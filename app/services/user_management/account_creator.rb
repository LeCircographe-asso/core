module UserManagement
  class AccountCreator < BaseService

    attribute :person
    attribute :user_email, :string
    attribute :user_password, :string
    attribute :user_system_role, :string, default: "web_visitor"
    attribute :created_by_admin, :boolean, default: false
    attribute :cgu, :string
    attribute :privacy_policy, :string

    validates :person, presence: true
    validates :user_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :user_password, presence: true, length: { minimum: 6 }
    validates :user_system_role, inclusion: { in: %w[super_admin admin volunteer web_visitor] }
    validate :email_uniqueness

    def call
      return failure("Invalid data: #{errors.full_messages.join(', ')}") unless valid?

      begin
        ActiveRecord::Base.transaction do
          # Vérifier si la Person a déjà un User
          if person.user.present?
            return failure("Person already has a user account")
          end

          # Créer le User
          user = person.build_user(
            email_address: user_email,
            password: user_password,
            password_confirmation: user_password,
            system_role: user_system_role,
            created_by_admin: created_by_admin
          )

          # Ajouter les validations CGU si fournies
          if cgu.present?
            user.cgu = cgu
          end

          if privacy_policy.present?
            user.privacy_policy = privacy_policy
          end

          user.save!

          # Instrumentation pour audit
          ActiveSupport::Notifications.instrument(
            "user_account.created",
            person_id: person.id,
            user_id: user.id,
            user_email: user_email,
            system_role: user_system_role,
            created_by_admin: created_by_admin
          )

          success(user: user, message: "User account created successfully")
        end
      rescue ActiveRecord::RecordInvalid => e
        failure("Validation error: #{e.message}")
      rescue => e
        Rails.logger.error "[AccountCreator] Error: #{e.message}"
        failure("Error creating user account: #{e.message}")
      end
    end

    private

    def email_uniqueness
      return if user_email.blank?

      if User.exists?(email_address: user_email)
        errors.add(:user_email, "has already been taken")
      end
    end

    # success et failure hérités de BaseService
  end
end
