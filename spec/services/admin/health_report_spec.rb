# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::HealthReport do
  describe "#call" do
    it "reports payment anomalies" do
      person = create(:person)
      recorder = create(:user, :admin)

      payment_without_lines = create(:payment, person: person, recorded_by: recorder, total_cents: 1_000)
      mismatched_payment = create(:payment, person: person, recorded_by: recorder, total_cents: 2_000)
      create(:payment_line,
             payment: mismatched_payment,
             item: create(:membership_type),
             item_type: "MembershipType",
             amount_cents: 1_500)

      legacy_payment = create(:payment, person: person, recorded_by: recorder, total_cents: 500)
      legacy_line = create(:payment_line,
                           payment: legacy_payment,
                           item: create(:membership_type),
                           item_type: "MembershipType",
                           amount_cents: 500,
                           description: "Donation")
      PaymentLine.connection.execute(
        PaymentLine.sanitize_sql_array(
          [
            "UPDATE payment_lines SET item_type = ?, item_id = ? WHERE id = ?",
            "Payment",
            legacy_payment.id,
            legacy_line.id
          ]
        )
      )

      report = described_class.new.call

      expect(report.payments_without_lines_count).to eq(1)
      expect(report.payments_without_lines.map(&:id)).to include(payment_without_lines.id)

      expect(report.payments_with_mismatched_totals_count).to eq(1)
      expect(report.payments_with_mismatched_totals.map(&:id)).to include(mismatched_payment.id)

      expect(report.legacy_donation_lines_count).to eq(1)
      expect(report.legacy_donation_lines.map(&:id)).to include(legacy_line.id)
    end

    it "reports contribution invariant issues" do
      person = create(:person, :with_active_membership)

      invalid_day = create(
        :contribution,
        person: person,
        contribution_formula: create(:contribution_formula, :day),
        purchased_at: Time.current,
        expires_at: Time.current.end_of_day
      )
      Contribution.connection.execute(
        Contribution.sanitize_sql_array(
          [ "UPDATE contributions SET sessions_remaining = ? WHERE id = ?", 2, invalid_day.id ]
        )
      )

      invalid_trimester = create(
        :contribution,
        person: person,
        contribution_formula: create(:contribution_formula, :trimester),
        expires_at: 3.months.from_now
      )
      Contribution.connection.execute(
        Contribution.sanitize_sql_array(
          [ "UPDATE contributions SET sessions_remaining = ? WHERE id = ?", 3, invalid_trimester.id ]
        )
      )

      report = described_class.new.call

      expect(report.contribution_invariant_issues_count).to eq(2)
      expect(report.contribution_invariant_issues.map { |issue| issue.contribution.id }).to include(invalid_day.id, invalid_trimester.id)
    end
  end
end
