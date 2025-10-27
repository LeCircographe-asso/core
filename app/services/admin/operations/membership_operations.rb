require "ostruct"

module Admin
  module Operations
    class MembershipOperations
      def initialize(actor:)
        @actor = actor
      end

      # Créer adhésion + paiement + traitement
      def create_membership_with_payment(person:, membership_type:, payment_method: :cash)
        ActiveRecord::Base.transaction do
          # 1. Utiliser service métier People::MembershipCreator
          result = People::MembershipCreator.new(
            person: person,
            membership_type_id: membership_type.id,
            payment_method: payment_method,
            recorded_by_id: @actor.id
          ).call

          return result unless result.success?

          # 2. Audit trail (orchestration admin)
          log_membership_creation(person, result.membership)

          result
        end
      end

      private

      def log_membership_creation(person, membership)
        # Rails 8.1 structured events si besoin
        Rails.logger.info "Admin #{@actor.id} created membership for person #{person.id}"
      end
    end
  end
end
