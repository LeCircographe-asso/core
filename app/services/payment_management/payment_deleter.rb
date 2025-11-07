module PaymentManagement
  class PaymentDeleter < BaseService
    attribute :payment_id, :integer
    attribute :deleted_by_id, :integer
    attribute :reason, :string

    validates :payment_id, presence: true
    validates :deleted_by_id, presence: true
    validates :reason, presence: true

    def call
      return failure("Invalid deletion data: #{errors.full_messages.join(', ')}") unless valid?

      begin
        ActiveRecord::Base.transaction do
          # Find the payment and deleter
          payment = Payment.find(payment_id)
          deleted_by = User.find(deleted_by_id)

          # Check permissions
          unless deleted_by.super_admin? || deleted_by.admin?
            return failure("Insufficient permissions to delete payment")
          end

          # Check if payment can be deleted (not already cancelled)
          if payment.status == "cancel"
            return failure("Payment is already cancelled")
          end

          # Soft delete by marking as cancelled
          if payment.update!(status: :cancel, notes: "#{payment.notes} - Cancelled: #{reason}")
            # Clear caches
            clear_payment_caches

            # Instrumentation pour audit
            ActiveSupport::Notifications.instrument(
              "payment.cancelled",
              payment_id: payment.id,
              person_id: payment.person_id,
              deleted_by_id: deleted_by_id,
              reason: reason
            )

            success(payment: payment, message: "Payment cancelled successfully")
          else
            failure("Failed to cancel payment: #{payment.errors.full_messages.join(', ')}")
          end
        end
      rescue ActiveRecord::RecordNotFound => e
        failure("Payment or User not found: #{e.message}")
      rescue ActiveRecord::RecordInvalid => e
        failure("Validation error: #{e.message}")
      rescue => e
        Rails.logger.error "[PaymentDeleter] Error: #{e.message}"
        failure("Unexpected error: #{e.message}")
      end
    end

    private

    def clear_payment_caches
      # Clear Rails cache to ensure payment totals are recalculated
      Rails.cache.delete("total_successful_payments")
      Rails.cache.delete("total_donations")

      # Clear view fragment caches
      expire_fragment(/payments_summary/)
      expire_fragment(/payments_total_amount/)
    end

    def expire_fragment(pattern)
      # This would typically be handled by the controller
      # For now, we'll just log it
      Rails.logger.info "Cache fragment expired: #{pattern}"
    end
    # success et failure hérités de BaseService
  end
end
