# frozen_string_literal: true

module PaymentManagement
  class RefundCreator
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :payment_id, :integer
    attribute :amount_cents, :integer
    attribute :refund_method, :string
    attribute :recorded_by_id, :integer
    attribute :reason, :string
    attribute :notes, :string

    validates :payment_id, presence: true
    validates :amount_cents, presence: true, numericality: { greater_than: 0 }
    validates :refund_method, presence: true, inclusion: { in: %w[cash card transfer check] }
    validates :recorded_by_id, presence: true
    validates :reason, presence: true

    def call
      return failure('Invalid refund data') unless valid?

      begin
        ActiveRecord::Base.transaction do
          # Find the payment and user
          payment = Payment.find(payment_id)
          recorded_by = User.find(recorded_by_id)

          # Validate refund amount doesn't exceed payment amount
          return failure('Refund amount cannot exceed original payment amount') if amount_cents > payment.amount_cents

          # Check if total refunds would exceed payment amount
          total_refunded = payment.refunds.sum(:amount_cents)
          return failure('Total refunds would exceed original payment amount') if total_refunded + amount_cents > payment.amount_cents

          # Create refund
          refund = payment.refunds.create!(
            amount_cents: amount_cents,
            refund_method: refund_method,
            recorded_by: recorded_by,
            reason: reason,
            notes: notes
          )

          success(refund: refund, message: 'Refund created successfully')
        end
      rescue ActiveRecord::RecordNotFound => e
        failure("Payment or User not found: #{e.message}")
      rescue ActiveRecord::RecordInvalid => e
        failure("Validation error: #{e.message}")
      rescue StandardError => e
        failure("Unexpected error: #{e.message}")
      end
    end

    # success et failure hérités de BaseService
  end
end
