require "ostruct"

module Admin
  module Operations
    class UserAccountOperations
      def initialize(actor:)
        @actor = actor
      end

      # Créer ou lier compte User à Person
      def ensure_user_account_for(person:, email: nil, system_role: "web_visitor")
        email ||= person.email

        return failure("Email required") if email.blank?

        ActiveRecord::Base.transaction do
          # Chercher User existant
          existing_user = User.find_by(email_address: email)

          if existing_user
            link_existing_user(person, existing_user)
          else
            create_new_user(person, email, system_role)
          end
        end
      end

      private

      def link_existing_user(person, user)
        return failure("User already linked to #{user.person.full_name}") if user.person.present?

        user.update!(person: person)
        success(user, "User account linked successfully")
      end

      def create_new_user(person, email, system_role)
        # Utiliser service métier People::UserAccountCreator
        People::UserAccountCreator.new(
          person: person,
          user_email: email,
          user_password: SecureRandom.hex(8),
          user_system_role: system_role,
          created_by_admin: true
        ).call
      end

      def success(user, message)
        OpenStruct.new(success?: true, user: user, message: message)
      end

      def failure(message)
        OpenStruct.new(success?: false, errors: [ message ], message: message)
      end
    end
  end
end
