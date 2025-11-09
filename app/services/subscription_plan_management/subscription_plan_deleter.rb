module SubscriptionPlanManagement
  class SubscriptionPlanDeleter < BaseService
    attribute :subscription_plan_id, :integer
    attribute :deleted_by_id, :integer

    validates :subscription_plan_id, presence: true
    validates :deleted_by_id, presence: true

    def call
      return failure("Invalid data: #{errors.full_messages.join(', ')}") unless valid?

      begin
        subscription_plan = SubscriptionPlan.find(subscription_plan_id)
        deleted_by = User.find(deleted_by_id)

        # Vérifier les permissions (seul super_admin peut supprimer)
        unless deleted_by.super_admin?
          return failure("Seul le super-admin peut supprimer des plans de cotisation")
        end

        # Vérifier que le plan n'est pas utilisé
        if subscription_plan.book_of_entries.any?
          return failure("Impossible de supprimer ce plan car il est utilisé par des carnets d'entrées")
        end

        ActiveRecord::Base.transaction do
          subscription_plan.destroy!

          # Instrumentation pour audit
          ActiveSupport::Notifications.instrument(
            "subscription_plan.deleted",
            subscription_plan_id: subscription_plan.id,
            deleted_by_id: deleted_by_id
          )

          success(message: "Subscription plan deleted successfully")
        end
      rescue ActiveRecord::RecordNotFound => e
        failure("Subscription plan or User not found: #{e.message}")
      rescue => e
        Rails.logger.error "[SubscriptionPlanDeleter] Error: #{e.message}"
        failure("Error deleting subscription plan: #{e.message}")
      end
    end

    private

    # success et failure hérités de BaseService
  end
end
