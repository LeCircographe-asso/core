module PaymentManagement
  class PaymentUpdater < BaseService

    attribute :payment_id, :integer
    attribute :total_cents, :integer
    attribute :payment_method, :string
    attribute :status, :string
    attribute :notes, :string
    attribute :updated_by_id, :integer

    validates :payment_id, presence: true
    validates :updated_by_id, presence: true
    # total_cents, payment_method, status, notes sont optionnels (update partiel)
    validates :total_cents, numericality: { greater_than: 0 }, allow_nil: true
    validates :payment_method, inclusion: { in: %w[cash card transfer check offered] }, allow_nil: true
    validates :status, inclusion: { in: %w[pending success failed cancelled] }, allow_nil: true

    def call
      return failure("Invalid payment data: #{errors.full_messages.join(', ')}") unless valid?

      begin
        ActiveRecord::Base.transaction do
          # Find the payment and updater
          payment = Payment.find(payment_id)
          updated_by = User.find(updated_by_id)

          # Check permissions
          unless updated_by.super_admin? || updated_by.admin?
            return failure("Insufficient permissions to update payment")
          end

          # Update payment (only update provided attributes)
          update_attrs = {}
          update_attrs[:total_cents] = total_cents if total_cents.present?
          update_attrs[:payment_method] = payment_method if payment_method.present?
          update_attrs[:status] = status if status.present?
          update_attrs[:notes] = notes if notes.present?
          
          if payment.update!(update_attrs)
            # Instrumentation pour audit
            ActiveSupport::Notifications.instrument(
              "payment.updated",
              payment_id: payment.id,
              person_id: payment.person_id,
              updated_by_id: updated_by_id,
              changes: payment.previous_changes
            )

            success(payment: payment, message: "Payment updated successfully")
          else
            failure("Failed to update payment: #{payment.errors.full_messages.join(', ')}")
          end
        end
      rescue ActiveRecord::RecordNotFound => e
        failure("Payment or User not found: #{e.message}")
      rescue ActiveRecord::RecordInvalid => e
        failure("Validation error: #{e.message}")
      rescue => e
        Rails.logger.error "[PaymentUpdater] Error: #{e.message}"
        failure("Unexpected error: #{e.message}")
      end
    end

    private

    # success et failure hérités de BaseService
  end
end
