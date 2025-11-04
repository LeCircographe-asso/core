module SubscriptionManagement
  class SubscriptionCreator < BaseService

    attribute :person
    attribute :subscription_plan_id, :integer
    attribute :payment_method, :string, default: "cash"
    attribute :recorded_by_id, :integer
    attribute :record_attendance, :boolean, default: false
    attribute :custom_amount_cents, :integer
    attribute :offer_reason, :string

    validates :person, presence: true
    validates :subscription_plan_id, presence: true
    validates :payment_method, presence: true
    validates :recorded_by_id, presence: true

    def call
      return failure("Invalid data: #{errors.full_messages.join(', ')}") unless valid?

      begin
        subscription_plan = SubscriptionPlan.find(subscription_plan_id)
        recorded_by = User.find(recorded_by_id)

        # Déléguer vers la logique existante dans Person
        result = person.create_subscription!(
          subscription_plan,
          payment_method: payment_method.to_sym,
          recorded_by: recorded_by,
          record_attendance: record_attendance,
          custom_amount_cents: custom_amount_cents,
          offer_reason: offer_reason
        )

        # Instrumentation pour audit
        ActiveSupport::Notifications.instrument(
          "subscription.created",
          person_id: person.id,
          book_of_entry_id: result[:book_of_entry].id,
          subscription_plan: subscription_plan.name,
          payment_method: payment_method,
          recorded_by_id: recorded_by_id,
          amount_cents: result[:payment].total_cents
        )

          success(book_of_entry: result[:book_of_entry], payment: result[:payment], message: "Subscription created successfully")
      rescue ActiveRecord::RecordNotFound => e
        failure("Record not found: #{e.message}")
      rescue => e
        Rails.logger.error "[SubscriptionCreator] Error: #{e.message}"
        failure("Error creating subscription: #{e.message}")
      end
    end

    private

    # success et failure hérités de BaseService
  end
end


