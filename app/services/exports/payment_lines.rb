# frozen_string_literal: true

module Exports
  # One row per payment line: the accounting grain (a payment can mix
  # membership, contributions and donation, for several beneficiaries).
  class PaymentLines < Base
    export_version 1
    period_on Payment, :created_at

    column(:payment_line_id, &:id)
    column(:payment_uuid) { |line| line.payment.uuid }
    column(:paid_at) { |line| line.payment.created_at }
    column(:payment_status) { |line| line.payment.status }
    column(:payment_method) { |line| line.payment.payment_method }
    column(:payment_total_euros) { |line| euros(line.payment.total_cents) }
    column(:line_type, &:item_type)
    column(:line_label, &:item_description)
    column(:line_amount_euros) { |line| euros(line.amount_cents) }
    person_columns(:beneficiary) { |line| line.person || line.payment.person }
    person_columns(:payer) { |line| line.payment.person }
    column(:recorded_by_user_id) { |line| line.payment.recorded_by_id }
    column(:offer_reason) { |line| line.payment.offer_reason }
    column(:anonymized) { |line| line.payment.anonymized_at.present? }

    private

    # No polymorphic `item` preload: legacy "MembershipUpgrade" lines have no
    # model class, so `includes(:item)` would raise NameError for the whole export.
    def scope
      PaymentLine.joins(:payment).includes(:person, payment: :person)
    end
  end
end
