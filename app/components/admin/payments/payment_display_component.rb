# frozen_string_literal: true

module Admin
  module Payments
    class PaymentDisplayComponent < ViewComponent::Base
      def initialize(payment:)
        @payment = payment
      end

      attr_reader :payment

      def display_date
        if payment.created_at.present?
          payment.created_at.strftime('%d/%m/%Y')
        else
          '-'
        end
      end

      def display_person
        if payment.person.present?
          payment.person.full_name.presence || "Personne ##{payment.person.id}"
        else
          'Personne inconnue'
        end
      end

      def display_status
        content_tag :span,
                    class: "px-2 inline-flex text-xs leading-5 font-semibold rounded-full #{payment.status_badge_class}" do
          payment.status_humanized
        end
      end

      def display_amount
        return '-' if payment.total_cents.blank?

        number_to_currency(payment.price_euros, unit: '€', separator: ',', delimiter: ' ')
      end

      def display_payment_method
        payment.payment_method_humanized
      end

      def display_payment_lines
        if payment.payment_lines.any?
          payment.payment_lines.map do |line|
            content_tag :div, class: 'text-xs' do
              "#{line.description || line.item_type}: #{number_to_currency(line.amount_cents / 100.0, unit: '€', separator: ',', delimiter: ' ')}"
            end
          end.join.html_safe
        else
          content_tag :span, '-', class: 'text-gray-400'
        end
      end

      def display_recorded_by
        if payment.recorded_by.present?
          payment.recorded_by.email_address || "Utilisateur ##{payment.recorded_by.id}"
        else
          'Inconnu'
        end
      end

      def format_currency(amount_cents)
        return '-' if amount_cents.blank?

        number_to_currency(amount_cents / 100.0, unit: '€', separator: ',', delimiter: ' ')
      end
    end
  end
end
