# frozen_string_literal: true

require "ostruct"

module People
  class PaymentUpdater
    include ActiveModel::Model
    include ActiveModel::Attributes

    Result = Struct.new(:success?, :payment, :errors, :message, keyword_init: true)

    attr_accessor :payment

    attribute :payment_id, :integer
    attribute :total_cents, :integer
    attribute :payment_method, :string
    attribute :status, :string
    attribute :notes, :string
    attribute :offer_reason, :string
    attribute :updated_by_id, :integer

    validates :updated_by_id, presence: true
    validate :payment_identifier_present
    validates :total_cents, numericality: { greater_than: 0 }, allow_nil: true
    validates :payment_method, inclusion: { in: %w[cash card cheque transfer offered] }, allow_nil: true
    validates :status, inclusion: { in: %w[pending success cancel] }, allow_nil: true
    validate :offer_reason_required_for_offered_update

    def call
      return failure("Invalid payment data: #{errors.full_messages.join(', ')}") unless valid?

      target_payment = resolve_payment
      updater = resolve_updater

      return failure("Insufficient permissions to update payment") unless updater.super_admin? || updater.admin?

      update_attrs = build_update_attributes

      ActiveRecord::Base.transaction do
        target_payment.update!(update_attrs) if update_attrs.any?

        ActiveSupport::Notifications.instrument(
          "payment.updated",
          payment_id: target_payment.id,
          person_id: target_payment.person_id,
          updated_by_id: updater.id,
          changes: target_payment.previous_changes
        )

        success(payment: target_payment, message: "Payment updated successfully")
      end
    rescue ActiveRecord::RecordNotFound => e
      failure("Record not found: #{e.message}")
    rescue ActiveRecord::RecordInvalid => e
      failure("Validation error: #{e.message}")
    rescue StandardError => e
      Rails.logger.error("[People::PaymentUpdater] #{e.class}: #{e.message}\n#{e.backtrace.take(5).join("\n")}")
      failure("Error updating payment: #{e.message}")
    end

    private

    def resolve_payment
      return payment if payment.present?

      Payment.find(payment_id)
    end

    def resolve_updater
      User.find(updated_by_id)
    end

    def build_update_attributes
      {}.tap do |attrs|
        attrs[:total_cents] = total_cents if total_cents.present?
        attrs[:payment_method] = payment_method if payment_method.present?
        attrs[:status] = status if status.present?
        attrs[:notes] = notes if notes.present?
        attrs[:offer_reason] = normalized_offer_reason if should_update_offer_reason?
        attrs[:offer_reason] = nil if clears_offer_reason?
      end
    end

    def payment_identifier_present
      errors.add(:payment_id, "must be provided") if payment.blank? && payment_id.blank?
    end

    def normalized_offer_reason
      offer_reason.to_s.strip.presence
    end

    def should_update_offer_reason?
      offer_reason.present? || payment_method == "offered"
    end

    def clears_offer_reason?
      payment_method.present? && payment_method != "offered"
    end

    def resulting_payment_method
      payment_method.presence || resolve_payment.payment_method
    end

    def offer_reason_required_for_offered_update
      return unless resulting_payment_method == "offered"
      return if normalized_offer_reason.present? || resolve_payment.offer_reason.present?

      errors.add(:offer_reason, "must be provided for an offered payment")
    rescue ActiveRecord::RecordNotFound
      nil
    end

    def success(payment:, message:)
      Result.new(success?: true, payment: payment, errors: [], message: message)
    end

    def failure(message, errors = nil)
      Result.new(success?: false, payment: nil, errors: Array(errors || message), message: message)
    end
  end
end
