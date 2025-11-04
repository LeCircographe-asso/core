module SubscriptionManagement
  class SubscriptionUpgrader < BaseService

    attribute :person
    attribute :from_book_id, :integer
    attribute :to_plan_id, :integer
    attribute :payment_method, :string, default: "cash"
    attribute :recorded_by_id, :integer

    validates :person, presence: true
    validates :from_book_id, presence: true
    validates :to_plan_id, presence: true
    validates :payment_method, presence: true
    validates :recorded_by_id, presence: true

    def call
      return failure("Invalid data: #{errors.full_messages.join(', ')}") unless valid?

      begin
        recorded_by = User.find(recorded_by_id)

        # Déléguer vers la logique existante dans Person
        result = person.upgrade_subscription!(
          from_book_id: from_book_id,
          to_plan_id: to_plan_id,
          payment_method: payment_method.to_sym,
          recorded_by: recorded_by
        )

        # Instrumentation pour audit
        ActiveSupport::Notifications.instrument(
          "subscription.upgraded",
          person_id: person.id,
          from_book_id: from_book_id,
          to_plan_id: to_plan_id,
          payment_method: payment_method,
          recorded_by_id: recorded_by_id,
          amount_cents: result[:payment]&.total_cents || 0,
          credit_applied: result[:credit_applied] || 0
        )

          success(
            book_of_entry: result[:new_book],
            payment: result[:payment],
            credit_applied: result[:credit_applied] || 0,
            message: "Subscription upgraded successfully"
          )
      rescue ActiveRecord::RecordNotFound => e
        failure("Record not found: #{e.message}")
      rescue => e
        Rails.logger.error "[SubscriptionUpgrader] Error: #{e.message}"
        failure("Error upgrading subscription: #{e.message}")
      end
    end

    private

    # success et failure hérités de BaseService
  end
end

