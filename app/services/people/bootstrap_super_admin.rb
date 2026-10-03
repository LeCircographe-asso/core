# frozen_string_literal: true

module People
  # Crée le tout premier super_admin d'une base vide (production/staging), sans passer par les seeds
  # (qui créent des comptes de démonstration). Délègue à People::Register : Person + User restent liés.
  # Refuse de tourner dès qu'un super_admin existe : les admins suivants se créent depuis l'interface.
  class BootstrapSuperAdmin
    include ActiveModel::Model
    include ActiveModel::Attributes

    MIN_PASSWORD_LENGTH = 12

    Result = Struct.new(:success?, :user, :errors, :message, keyword_init: true)

    attribute :email, :string
    attribute :first_name, :string
    attribute :last_name, :string
    attribute :password, :string

    validates :email, :first_name, :last_name, presence: true
    validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }
    validates :password, length: { minimum: MIN_PASSWORD_LENGTH }, confirmation: true
    validate :no_super_admin_yet

    def call
      return failure(errors.full_messages.first, errors.full_messages) unless valid?

      result = People::Register.new(
        person_params: { first_name: first_name, last_name: last_name, email: email, is_minor: false },
        newsletter_source: "bootstrap",
        create_user_account: true,
        user_params: { email_address: email, system_role: "super_admin", created_by_admin: true, password: password }
      ).call

      return failure(result.message, result.errors) unless result.success?

      Result.new(success?: true, user: result.user, errors: [], message: nil)
    end

    private

    def no_super_admin_yet
      errors.add(:base, I18n.t("services.errors.super_admin_already_exists")) if User.super_admin.exists?
    end

    def failure(message, error_list = nil)
      Result.new(success?: false, user: nil, errors: Array(error_list || message), message: message)
    end
  end
end
