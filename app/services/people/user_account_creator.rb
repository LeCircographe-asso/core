require "ostruct"

module People
  class UserAccountCreator
    include ActiveModel::Model
    include ActiveModel::Attributes

    Result = Struct.new(:success?, :user, :errors, :message, :created, :generated_password, keyword_init: true)

    attribute :person
    attribute :email_address, :string
    attribute :system_role, :string, default: "web_visitor"
    attribute :password, :string
    attribute :created_by_admin, :boolean, default: false
    attribute :cgu, :boolean, default: true
    attribute :privacy_policy, :boolean, default: true

    validates :person, presence: true
    validates :system_role, inclusion: { in: %w[super_admin admin volunteer web_visitor] }, allow_blank: true

    def call
      return failure("Invalid data", errors.full_messages) unless valid?

      ActiveRecord::Base.transaction do
        target_person = person.reload
        existing_user = target_person.user

        if existing_user
          update_user(existing_user)
        else
          create_user(target_person)
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      failure("Validation error: #{e.message}")
    rescue => e
      Rails.logger.error("[People::UserAccountCreator] #{e.class}: #{e.message}\n#{e.backtrace.take(5).join("\n")}")
      failure("Error creating or updating user account: #{e.message}")
    end

    private

    def update_user(user)
      attrs = {}
      attrs[:email_address] = email_address if email_address.present? && email_address != user.email_address
      attrs[:system_role] = system_role if system_role.present? && system_role != user.system_role

      if attrs.empty? && password.blank?
        return success(user: user, message: "User already up to date", created: false)
      end

      user.assign_attributes(attrs) if attrs.any?
      user.password = password if password.present?
      user.password_confirmation = password if password.present?
      user.save!

      success(user: user, message: "User account updated successfully", created: false)
    end

    def create_user(target_person)
      if target_person.user.present?
        return failure("Cette personne a déjà un compte web. ID User: #{target_person.user.id}")
      end

      final_email = email_address.presence || target_person.email
      raise "An email is required to create a user account" if final_email.blank?

      generated_password = password.presence || SecureRandom.hex(12)

      user = target_person.build_user(
        email_address: final_email,
        password: generated_password,
        password_confirmation: generated_password,
        system_role: system_role.presence || "web_visitor",
        created_by_admin: created_by_admin
      )

      user.cgu = cgu
      user.privacy_policy = privacy_policy

      user.save!

      success(
        user: user,
        message: "User account created successfully",
        created: true,
        generated_password: password.present? ? nil : generated_password
      )
    end

    def success(user:, message:, created:, generated_password: nil)
      Result.new(
        success?: true,
        user: user,
        errors: [],
        message: message,
        created: created,
        generated_password: generated_password
      )
    end

    def failure(message, error_list = nil)
      Result.new(
        success?: false,
        user: nil,
        errors: Array(error_list || message),
        message: message,
        created: false,
        generated_password: nil
      )
    end
  end
end
