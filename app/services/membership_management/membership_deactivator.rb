module MembershipManagement
  class MembershipDeactivator < BaseService

    attribute :membership_id, :integer
    attribute :deactivated_by_id, :integer
    attribute :reason, :string

    validates :membership_id, presence: true
    validates :deactivated_by_id, presence: true
    validates :reason, presence: true

    def call
      return failure("Invalid data: #{errors.full_messages.join(', ')}") unless valid?

      begin
        membership = Membership.find(membership_id)
        deactivated_by = User.find(deactivated_by_id)

        # Vérifier les permissions
        unless can_deactivate_membership?(membership, deactivated_by)
          return failure("Insufficient permissions to deactivate this membership")
        end

        ActiveRecord::Base.transaction do
          membership.update!(status: :inactive)

          # Instrumentation pour audit
          ActiveSupport::Notifications.instrument(
            "membership.deactivated",
            membership_id: membership.id,
            person_id: membership.person_id,
            deactivated_by_id: deactivated_by_id,
            reason: reason
          )

          success(membership: membership, message: "Adhésion désactivée avec succès")
        end
      rescue ActiveRecord::RecordNotFound => e
        failure("Membership or User not found: #{e.message}")
      rescue ActiveRecord::RecordInvalid => e
        failure("Validation error: #{e.message}")
      rescue => e
        Rails.logger.error "[MembershipDeactivator] Error: #{e.message}"
        failure("Error deactivating membership: #{e.message}")
      end
    end

    private

    def can_deactivate_membership?(membership, deactivated_by)
      # Un admin/super_admin peut désactiver n'importe quelle adhésion
      deactivated_by.super_admin? || deactivated_by.admin?
    end

    # success et failure hérités de BaseService
  end
end


