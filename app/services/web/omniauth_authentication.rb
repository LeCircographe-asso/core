# frozen_string_literal: true

module Web
  # Authentifie ou inscrit un utilisateur via un provider OmniAuth (ex. Google).
  # Priorité de résolution :
  #   1. Un User a déjà ce provider/uid -> connexion directe.
  #   2. Une Person active existe avec cet email -> on lie le compte (ou on
  #      récupère le User existant de cette Person) plutôt que de dupliquer.
  #   3. Sinon, inscription complète via People::Register (même chemin que
  #      l'inscription classique), avec un mot de passe généré.
  class OmniauthAuthentication < BaseService
    attribute :auth

    validates :auth, presence: true

    def call
      return failure(I18n.t("omniauth_callbacks.invalid_credentials")) unless valid?
      return failure(I18n.t("omniauth_callbacks.invalid_credentials")) if uid.blank? || email.blank?

      existing_by_identity = User.find_by(provider: provider, uid: uid)
      return success(user: existing_by_identity) if existing_by_identity

      existing_person = Person.active.find_by(email: email)
      return link_or_reuse_account(existing_person) if existing_person

      register_new_account
    end

    private

    def provider
      auth.provider
    end

    def uid
      auth.uid
    end

    def email
      auth.info&.email&.strip&.downcase
    end

    def first_name
      auth.info&.first_name.presence || auth.info&.name.presence || "Web"
    end

    def last_name
      auth.info&.last_name.presence || "User"
    end

    def link_or_reuse_account(person)
      user = person.user

      if user.nil?
        return failure(I18n.t("omniauth_callbacks.registration_disabled")) unless public_registration_enabled?

        user = person.build_user(
          email_address: email,
          password: SecureRandom.hex(20),
          system_role: "web_visitor",
          created_by_admin: false,
          provider: provider,
          uid: uid,
          cgu: true,
          privacy_policy: true
        )
        return failure(user.errors.full_messages.to_sentence) unless user.save

        user.welcome_send
        return success(user: user)
      end

      user.update!(provider: provider, uid: uid) if user.provider.blank?
      success(user: user)
    end

    def register_new_account
      return failure(I18n.t("omniauth_callbacks.registration_disabled")) unless public_registration_enabled?

      result = People::Register.new(
        person_params: { first_name: first_name, last_name: last_name, email: email },
        newsletter_subscribed: false,
        newsletter_source: "web_google",
        create_user_account: true,
        user_params: {
          email_address: email,
          system_role: "web_visitor",
          created_by_admin: false,
          cgu: true,
          privacy_policy: true,
          provider: provider,
          uid: uid
        },
        create_membership: false
      ).call

      return failure(result.message) unless result.success?

      success(user: result.user)
    end

    def public_registration_enabled?
      Rails.application.config.x.public_registration_enabled
    end
  end
end
