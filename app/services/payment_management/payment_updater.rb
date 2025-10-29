require "ostruct"

module PaymentManagement
  class PaymentUpdater
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :payment_id, :integer
    attribute :total_cents, :integer
    attribute :payment_method, :string
    attribute :status, :string
    attribute :notes, :string
    attribute :updated_by_id, :integer

    validates :payment_id, presence: true
    validates :total_cents, presence: true, numericality: { greater_than: 0 }
    validates :payment_method, presence: true, inclusion: { in: %w[cash card transfer check offered] }
    validates :status, presence: true, inclusion: { in: %w[pending success failed cancelled] }
    validates :updated_by_id, presence: true

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

          # Update payment
          if payment.update!(
            total_cents: total_cents,
            payment_method: payment_method,
            status: status,
            notes: notes
          )
            # Instrumentation pour audit
            ActiveSupport::Notifications.instrument(
              "payment.updated",
              payment_id: payment.id,
              person_id: payment.person_id,
              updated_by_id: updated_by_id,
              changes: payment.previous_changes
            )

            success(payment)
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

    def success(payment)
      OpenStruct.new(
        success?: true,
        payment: payment,
        message: "Payment updated successfully"
      )
    end

    def failure(message)
      OpenStruct.new(
        success?: false,
        errors: [message],
        message: message
      )
    end
  end
end
