module MembershipManagement
  class MembershipUpdater < BaseService
    attribute :membership_id, :integer
    attribute :membership_type_id, :integer
    attribute :started_at, :date
    attribute :ended_at, :date
    attribute :updated_by_id, :integer

    validates :membership_id, presence: true
    validates :membership_type_id, presence: true
    validates :updated_by_id, presence: true

    def call
      return failure("Invalid data: #{errors.full_messages.join(', ')}") unless valid?

      begin
        membership = Membership.find(membership_id)
        membership_type = MembershipType.find(membership_type_id)
        updated_by = User.find(updated_by_id)

        # Vérifier les permissions
        unless can_update_membership?(membership, updated_by)
          return failure("Insufficient permissions to update this membership")
        end

        ActiveRecord::Base.transaction do
          membership.update!(
            membership_type: membership_type,
            started_at: started_at || membership.started_at,
            ended_at: ended_at || membership.ended_at
          )

          # Instrumentation pour audit
          ActiveSupport::Notifications.instrument(
            "membership.updated",
            membership_id: membership.id,
            person_id: membership.person_id,
            membership_type_id: membership_type.id,
            updated_by_id: updated_by_id,
            changes: membership.previous_changes
          )

          success(membership: membership, message: "Adhésion mise à jour avec succès")
        end
      rescue ActiveRecord::RecordNotFound => e
        failure("Membership, MembershipType or User not found: #{e.message}")
      rescue ActiveRecord::RecordInvalid => e
        failure("Validation error: #{e.message}")
      rescue => e
        Rails.logger.error "[MembershipUpdater] Error: #{e.message}"
        failure("Error updating membership: #{e.message}")
      end
    end

    private

    def can_update_membership?(membership, updated_by)
      # Un admin/super_admin peut mettre à jour n'importe quelle adhésion
      updated_by.super_admin? || updated_by.admin?
    end

    # success et failure hérités de BaseService
  end
end
