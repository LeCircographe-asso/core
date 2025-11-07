module PaymentManagement
  class PaymentRestorer < BaseService
    attribute :payment_id, :integer
    attribute :restored_by_id, :integer
    attribute :reason, :string

    validates :payment_id, presence: true
    validates :restored_by_id, presence: true
    validates :reason, presence: true

    def call
      return failure("Invalid restoration data: #{errors.full_messages.join(', ')}") unless valid?

      begin
        ActiveRecord::Base.transaction do
          # Find the payment and restorer
          payment = Payment.find(payment_id)
          restored_by = User.find(restored_by_id)

          # Check permissions
          unless restored_by.super_admin? || restored_by.admin?
            return failure("Insufficient permissions to restore payment")
          end

          # Check if payment can be restored (must be cancelled)
          unless payment.status == "cancel"
            return failure("Payment is not cancelled and cannot be restored")
          end

          # Restore by marking as success
          if payment.update!(status: :success, notes: "#{payment.notes} - Restored: #{reason}")
            # Clear caches
            clear_payment_caches

            # Instrumentation pour audit
            ActiveSupport::Notifications.instrument(
              "payment.restored",
              payment_id: payment.id,
              person_id: payment.person_id,
              restored_by_id: restored_by_id,
              reason: reason
            )

            success(payment: payment, message: "Payment restored successfully")
          else
            failure("Failed to restore payment: #{payment.errors.full_messages.join(', ')}")
          end
        end
      rescue ActiveRecord::RecordNotFound => e
        failure("Payment or User not found: #{e.message}")
      rescue ActiveRecord::RecordInvalid => e
        failure("Validation error: #{e.message}")
      rescue => e
        Rails.logger.error "[PaymentRestorer] Error: #{e.message}"
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
