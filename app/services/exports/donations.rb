# frozen_string_literal: true

module Exports
  # One row per donation line, with its tax receipt when issued.
  class Donations < Base
    export_version 1
    period_on Payment, :created_at

    column(:payment_line_id, &:id)
    column(:payment_uuid) { |line| line.payment.uuid }
    column(:donated_at) { |line| line.payment.created_at }
    column(:payment_status) { |line| line.payment.status }
    column(:payment_method) { |line| line.payment.payment_method }
    column(:amount_euros) { |line| euros(line.amount_cents) }
    column(:description, &:description)
    person_columns(:donor) { |line| line.person || line.payment.person }
    column(:receipt_number) { |line| line.donation_receipt&.number }
    column(:receipt_issued_at) { |line| line.donation_receipt&.issued_at }
    column(:anonymized) { |line| line.payment.anonymized_at.present? }

    private

    def scope
      PaymentLine.donations.joins(:payment).includes(:person, :donation_receipt, payment: :person)
    end
  end
end
