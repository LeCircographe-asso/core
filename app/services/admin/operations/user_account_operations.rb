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
        return failure("Email requis") unless email.present?

        ActiveRecord::Base.transaction do
          if person.user.present?
            return success(person.user, "Compte déjà existant")
          end
          
          existing_user = User.find_by(email_address: email)
          
          if existing_user
            handle_existing_user(person, existing_user, system_role)
          else
            create_new_user_for_person(person, email, system_role)
          end
        end
      end

      private

      def handle_existing_user(person, user, system_role)
        if user.person_id.nil?
          user.update!(person: person, system_role: system_role)
          log_admin_action("User #{user.id} lié à Person #{person.id}")
          success(user, "Compte web lié à #{person.full_name}")
        elsif user.person_id == person.id
          success(user, "Déjà lié")
        else
          other_person = user.person
          
          # Vérification avant fusion
          if other_person.payments.any? || other_person.memberships.any?
            log_admin_action("ATTENTION: Fusion Person #{other_person.id} (avec données financières) -> Person #{person.id}")
          end
          
          # Fusion avec audit
          merge_result = People::Merger.new(
            source: other_person,
            target: person,
            actor: @actor,
            merge_type: "admin_merge"
          ).call
          
          if merge_result.success?
            log_admin_action("Fusion réussie: Person #{other_person.id} -> Person #{person.id}")
            success(user, "Fusion effectuée: #{other_person.full_name} -> #{person.full_name}")
          else
            log_admin_action("ERREUR fusion: #{merge_result.message}")
            failure(merge_result.message)
          end
        end
      end
      
      def create_new_user_for_person(person, email, system_role)
        user_creation_result = People::UserAccountCreator.new(
          person: person,
          user_email: email,
          user_password: SecureRandom.hex(8), # Mot de passe temporaire
          user_system_role: system_role,
          created_by_admin: true
        ).call

        return failure(user_creation_result.errors.join(", ")) unless user_creation_result.success?

        success(user_creation_result.user, "Nouveau compte web créé ! Email: #{email}, Mot de passe temporaire généré.")
      end

      def success(user, message)
        OpenStruct.new(success?: true, user: user, message: message)
      end

      def failure(message)
        OpenStruct.new(success?: false, errors: [ message ], message: message)
      end

      def log_admin_action(message)
        Rails.logger.info("[ADMIN_MERGE] Admin: #{@actor&.email_address || 'unknown'} | #{message} | Time: #{Time.current}")
      end
    end
  end
end
