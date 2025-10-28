module Admin
  module Payments
    class PaymentSummaryComponent < ViewComponent::Base
      def initialize(payments:, total_amount: 0, total_donation: 0)
        @payments = payments
        @total_amount = total_amount
        @total_donation = total_donation
      end

      private

      attr_reader :payments, :total_amount, :total_donation

      def total_payments_count
        payments.count
      end

      def successful_payments_count
        payments.where(status: :success).count
      end

      def pending_payments_count
        payments.where(status: :pending).count
      end

      def cancelled_payments_count
        payments.where(status: :cancel).count
      end

      def format_currency(amount_cents)
        return "0,00 €" if amount_cents.blank? || amount_cents == 0
        
        number_to_currency(amount_cents / 100.0, unit: "€", separator: ",", delimiter: " ")
      end

      def total_amount_formatted
        format_currency(total_amount)
      end

      def total_donation_formatted
        format_currency(total_donation)
      end

      def total_revenue
        total_amount + total_donation
      end

      def total_revenue_formatted
        format_currency(total_revenue)
      end
    end
  end
end
