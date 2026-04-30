# frozen_string_literal: true

module AccountClaimManagement
  class AccountClaimConfirmer < BaseService
    attribute :confirmation_token, :string

    validates :confirmation_token, presence: true

    def call
      return failure("Invalid data: #{errors.full_messages.join(', ')}") unless valid?

      begin
        claim = AccountClaim.find_by!(confirmation_token: confirmation_token)

        return failure('Lien expiré (24h)') if claim.expired?

        return failure('Cette réclamation a déjà été confirmée') if claim.confirmed?

        user_person = resolve_user_person(claim)
        admin_person = claim.person

        if user_person.nil?
          link_result = People::AccountLinker.new(
            user: claim.user,
            target_person: admin_person,
            destroy_source_person: false,
            audit_reason: 'account_claim'
          ).call

          return failure("Erreur lors du rattachement du compte: #{link_result.message}") unless link_result.success?

          user_person = link_result.target_person
        else
          merge_result = People::AccountMerger.new(
            source_person: admin_person,
            target_person: user_person,
            actor_id: claim.user.id,
            merge_type: 'account_claim'
          ).call

          return failure("Erreur lors de la fusion: #{merge_result.message}") unless merge_result.success?
        end

        claim.update!(status: :confirmed)

        ActiveSupport::Notifications.instrument(
          'account_claim.confirmed',
          account_claim_id: claim.id,
          admin_person_id: admin_person.id,
          user_id: claim.user.id,
          user_person_id: user_person.id
        )

        success(
          claim: claim,
          user_person: user_person,
          user: user_person.user,
          message: '✅ Compte revendiqué ! Votre historique est maintenant disponible.'
        )
      rescue ActiveRecord::RecordNotFound => e
        failure("Account claim not found: #{e.message}")
      rescue StandardError => e
        Rails.logger.error "[AccountClaimConfirmer] Error: #{e.message}"
        Rails.logger.error "[AccountClaimConfirmer] Backtrace: #{e.backtrace.first(5).join('\n')}"
        failure("Error confirming account claim: #{e.message}")
      end
    end

    private

    def resolve_user_person(claim)
      claim.user.person
    end

    # success et failure hérités de BaseService
  end
end
