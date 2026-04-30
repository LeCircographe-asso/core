# frozen_string_literal: true

module MembershipTypeManagement
  class MembershipTypeDeleter < BaseService
    attribute :membership_type_id, :integer
    attribute :deleted_by_id, :integer

    validates :membership_type_id, presence: true
    validates :deleted_by_id, presence: true

    def call
      return failure(I18n.t("services.validation.invalid_data_with_details", details: errors.full_messages.join(", "))) unless valid?

      begin
        membership_type = MembershipType.find(membership_type_id)
        deleted_by = User.find(deleted_by_id)

        # Vérifier les permissions - seul le super_admin peut supprimer
        return failure("Seul le super-admin peut supprimer des types d'adhésion") unless deleted_by.super_admin?

        # Vérifier que le type n'est pas utilisé
        return failure("Impossible de supprimer ce type d'adhésion car il est utilisé par des membres") if membership_type.memberships.any?

        # Supprimer le type d'adhésion
        membership_type.destroy!

        # Instrumentation pour audit
        ActiveSupport::Notifications.instrument(
          "membership_type.deleted",
          membership_type_id: membership_type_id,
          deleted_by_id: deleted_by_id,
          name: membership_type.name
        )

        success(message: "Membership type deleted successfully")
      rescue ActiveRecord::RecordNotFound => e
        failure("MembershipType or User not found: #{e.message}")
      rescue StandardError => e
        Rails.logger.error "[MembershipTypeDeleter] Error: #{e.message}"
        failure("Error deleting membership type: #{e.message}")
      end
    end

    # success et failure hérités de BaseService
  end
end
