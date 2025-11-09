module SubscriptionPlanManagement
  class SubscriptionPlanUpdater < BaseService
    attribute :subscription_plan_id, :integer
    attribute :attributes, hash: true
    attribute :updated_by_id, :integer

    validates :subscription_plan_id, presence: true
    validates :updated_by_id, presence: true

    def call
      return failure("Invalid data: #{errors.full_messages.join(', ')}") unless valid?

      begin
        subscription_plan = SubscriptionPlan.find(subscription_plan_id)
        updated_by = User.find(updated_by_id)

        # Vérifier les permissions (seul super_admin peut modifier)
        unless updated_by.super_admin?
          return failure("Seul le super-admin peut modifier des plans de cotisation")
        end

        ActiveRecord::Base.transaction do
          subscription_plan.update!(attributes)

          # Instrumentation pour audit
          ActiveSupport::Notifications.instrument(
            "subscription_plan.updated",
            subscription_plan_id: subscription_plan.id,
            updated_by_id: updated_by_id,
            changes: subscription_plan.previous_changes
          )

          success(subscription_plan: subscription_plan, message: "Subscription plan updated successfully")
        end
      rescue ActiveRecord::RecordNotFound => e
        failure("Subscription plan or User not found: #{e.message}")
      rescue ActiveRecord::RecordInvalid => e
        failure("Validation error: #{e.message}")
      rescue => e
        Rails.logger.error "[SubscriptionPlanUpdater] Error: #{e.message}"
        failure("Error updating subscription plan: #{e.message}")
      end
    end

    private

    # success et failure hérités de BaseService
  end
end
