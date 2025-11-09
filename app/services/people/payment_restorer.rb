require "ostruct"

module People
  class PaymentRestorer
    include ActiveModel::Model
    include ActiveModel::Attributes

    Result = Struct.new(:success?, :payment, :errors, :message, keyword_init: true)

    attr_accessor :payment

    attribute :payment_id, :integer
    attribute :restored_by_id, :integer
    attribute :reason, :string

    validates :restored_by_id, presence: true
    validates :reason, presence: true
    validate :payment_identifier_present

    def call
      return failure("Invalid restoration data: #{errors.full_messages.join(', ')}") unless valid?

      target_payment = resolve_payment
      restorer = resolve_restorer

      unless restorer.super_admin? || restorer.admin?
        return failure("Insufficient permissions to restore payment")
      end

      unless target_payment.status == "cancel"
        return failure("Payment is not cancelled and cannot be restored")
      end

      ActiveRecord::Base.transaction do
        target_payment.update!(status: :success, notes: append_note(target_payment.notes, "Restored: #{reason}"))

        ActiveSupport::Notifications.instrument(
          "payment.restored",
          payment_id: target_payment.id,
          person_id: target_payment.person_id,
          restored_by_id: restorer.id,
          reason: reason
        )

        success(payment: target_payment, message: "Payment restored successfully")
      end
    rescue ActiveRecord::RecordNotFound => e
      failure("Record not found: #{e.message}")
    rescue ActiveRecord::RecordInvalid => e
      failure("Validation error: #{e.message}")
    rescue => e
      Rails.logger.error("[People::PaymentRestorer] #{e.class}: #{e.message}\n#{e.backtrace.take(5).join("\n")}")
      failure("Error restoring payment: #{e.message}")
    end

    private

    def resolve_payment
      return payment if payment.present?

      Payment.find(payment_id)
    end

    def resolve_restorer
      User.find(restored_by_id)
    end

    def append_note(existing_notes, suffix)
      [existing_notes.presence, suffix].compact.join(" - ")
    end

    def payment_identifier_present
      errors.add(:payment_id, "must be provided") if payment.blank? && payment_id.blank?
    end

    def success(payment:, message:)
      Result.new(success?: true, payment: payment, errors: [], message: message)
    end

    def failure(message, errors = nil)
      Result.new(success?: false, payment: nil, errors: Array(errors || message), message: message)
    end
  end
end
