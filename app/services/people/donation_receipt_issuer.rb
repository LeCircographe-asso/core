# frozen_string_literal: true

require "ostruct"

module People
  # Émet le reçu de don (métadonnées : numéro, émetteur, donateur — pas de PDF
  # stocké, voir DonationReceiptGenerator). Le numéro est séquentiel par année
  # civile ("AAAA-NNN"). Émetteur et donateur sont figés à l'émission plutôt
  # que résolus à l'affichage, pour rester une preuve stable même si l'adresse
  # de l'association ou de la personne change ensuite.
  #
  # Ne constitue pas un reçu fiscal (art. 200/238 bis CGI) : l'éligibilité
  # "intérêt général" de l'association n'est pas encore confirmée. Ne pas
  # ajouter de mention de réduction d'impôt tant que ce n'est pas tranché.
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
      return failure("Payment is not successful") unless target_line.payment.status == "success"
      return failure("Payment method does not represent a real monetary flow") if target_line.payment.payment_method == "offered"

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
        donor = target_line.payment.person

        DonationReceipt.create!(
          payment_line: target_line,
          number: next_number(issued_at.year),
          issued_at: issued_at,
          issuer: issuer_snapshot,
          issuer_address: issuer_address_snapshot,
          donor_name: donor.full_name,
          donor_address: address_snapshot(donor)
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

    def issuer_address_snapshot
      ENV.fetch("ASSOCIATION_RECEIPT_ADDRESS", "")
    end

    def address_snapshot(person)
      [ person.address, "#{person.zip_code} #{person.town}".strip, person.country ]
        .map(&:presence)
        .compact
        .join("\n")
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
