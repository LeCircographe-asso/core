# frozen_string_literal: true

require "ostruct"

module People
  # Émet le reçu fiscal (métadonnées : numéro, date d'émission, émetteur) d'une
  # ligne de paiement de don. Le numéro est séquentiel par année civile
  # ("AAAA-NNN"), ce qui correspond à l'usage courant des reçus de dons
  # associatifs en France (l'année du reçu est l'année de déclaration fiscale
  # du donateur). L'émetteur est figé à l'émission plutôt que résolu à
  # l'affichage, pour rester une preuve stable même si l'identité légale de
  # l'association change plus tard.
  class DonationReceiptIssuer
    include ActiveModel::Model
    include ActiveModel::Attributes

    Result = Struct.new(:success?, :donation_receipt, :errors, :message, keyword_init: true)

    MAX_ATTEMPTS = 3

    attr_accessor :payment_line

    attribute :payment_line_id, :integer
    attribute :issued_at, :datetime, default: -> { Time.current }

    validate :payment_line_identifier_present

    def call
      return failure("Invalid receipt data: #{errors.full_messages.join(', ')}") unless valid?

      target_line = resolve_payment_line
      return failure("Payment line not found") if target_line.blank?
      return failure("Payment line is not a donation") unless target_line.item_type == "Donation"

      existing = target_line.donation_receipt
      return failure("A receipt already exists for this donation", donation_receipt: existing) if existing.present?

      donation_receipt = create_receipt(target_line)

      ActiveSupport::Notifications.instrument(
        "donation.receipt_issued",
        donation_receipt_id: donation_receipt.id,
        payment_line_id: target_line.id
      )

      success(donation_receipt: donation_receipt, message: "Receipt issued successfully")
    rescue ActiveRecord::RecordInvalid => e
      failure("Validation error: #{e.message}")
    end

    private

    def resolve_payment_line
      return payment_line if payment_line.present?

      PaymentLine.find_by(id: payment_line_id)
    end

    def create_receipt(target_line)
      attempts = 0

      begin
        attempts += 1
        DonationReceipt.create!(
          payment_line: target_line,
          number: next_number(issued_at.year),
          issued_at: issued_at,
          issuer: issuer_snapshot
        )
      rescue ActiveRecord::RecordNotUnique
        raise if attempts >= MAX_ATTEMPTS

        retry
      end
    end

    def next_number(year)
      prefix = "#{year}-"
      last_number = DonationReceipt.where("number LIKE ?", "#{prefix}%").order(:number).pick(:number)
      sequence = last_number ? last_number.delete_prefix(prefix).to_i + 1 : 1
      format("%s%03d", prefix, sequence)
    end

    def issuer_snapshot
      ENV.fetch("ASSOCIATION_RECEIPT_ISSUER", "Le Circographe")
    end

    def payment_line_identifier_present
      errors.add(:payment_line_id, "must be provided") if payment_line.blank? && payment_line_id.blank?
    end

    def success(donation_receipt:, message:)
      Result.new(success?: true, donation_receipt: donation_receipt, errors: [], message: message)
    end

    def failure(message, donation_receipt: nil)
      Result.new(success?: false, donation_receipt: donation_receipt, errors: [ message ], message: message)
    end
  end
end
