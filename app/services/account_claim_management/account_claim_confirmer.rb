module AccountClaimManagement
  class AccountClaimConfirmer < BaseService
    attribute :confirmation_token, :string

    validates :confirmation_token, presence: true

    def call
      return failure("Invalid data: #{errors.full_messages.join(', ')}") unless valid?

      begin
        claim = AccountClaim.find_by!(confirmation_token: confirmation_token)

        if claim.expired?
          return failure("Lien expiré (24h)")
        end

        if claim.confirmed?
          return failure("Cette réclamation a déjà été confirmée")
        end

        ActiveRecord::Base.transaction do
          # Fusionner les données Person admin → User actuel
          admin_person = claim.person

          # Utiliser PersonManagement::PersonMerger pour fusionner correctement
          # Si user a déjà une Person, fusionner. Sinon, transférer admin_person vers user
          user_person = claim.user.person

          if user_person.nil?
            # Pas de Person pour user : transférer admin_person vers user
            admin_person.update!(user: claim.user)
            user_person = admin_person
          else
            # User a déjà une Person : fusionner admin_person → user_person
            merger = PersonManagement::PersonMerger.new(
              source: admin_person,
              target: user_person,
              actor: claim.user,
              merge_type: "admin_merge"
            )

            merger_result = merger.call

            unless merger_result.success?
              return failure("Erreur lors de la fusion: #{merger_result.message}")
            end

            # Après fusion, user_person reste la Person principale
            user_person.reload
          end

          # Marquer la réclamation comme confirmée
          claim.update!(status: :confirmed)

          # Instrumentation pour audit
          ActiveSupport::Notifications.instrument(
            "account_claim.confirmed",
            account_claim_id: claim.id,
            admin_person_id: admin_person.id,
            user_id: claim.user.id,
            user_person_id: user_person.id
          )

          success(
            claim: claim,
            user_person: user_person,
            user: user_person.user,
            message: "✅ Compte revendiqué ! Votre historique est maintenant disponible."
          )
        end
      rescue ActiveRecord::RecordNotFound => e
        failure("Account claim not found: #{e.message}")
      rescue => e
        Rails.logger.error "[AccountClaimConfirmer] Error: #{e.message}"
        Rails.logger.error "[AccountClaimConfirmer] Backtrace: #{e.backtrace.first(5).join('\n')}"
        failure("Error confirming account claim: #{e.message}")
      end
    end

    private

    # success et failure hérités de BaseService
  end
end
