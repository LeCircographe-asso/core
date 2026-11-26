# frozen_string_literal: true

require "rails_helper"

load Rails.root.join("ops/data_report.rb").to_s

RSpec.describe DataReport do
  describe ".report" do
    it "runs every check on the current schema (a rename must update ops/data_report.rb)" do
      report = described_class.report

      expect(report["checks"].select { |_name, value| value == "skipped" }).to be_empty
      expect(report["sqlite_integrity"]).to eq("ok")
      expect(report["tables"]).to include("people", "payments", "payment_lines")
    end

    it "counts a payment whose lines do not add up to its total" do
      payment = create(:payment, :with_membership_line, total_cents: 1500)
      payment.update_column(:total_cents, 2000) # rubocop:disable Rails/SkipsModelValidations -- simulate corrupt data

      expect(described_class.report["checks"]["payments_lines_sum_mismatch"]).to eq(1)
    end

    it "counts a payment with a total but no line" do
      create(:payment, total_cents: 1500)

      expect(described_class.report["checks"]["payments_without_lines"]).to eq(1)
    end

    it "accepts every line type PaymentLine allows and counts the others" do
      payment = create(:payment, :with_membership_line)
      PaymentLine.where(payment: payment).update_all(item_type: "MembershipUpgrade") # rubocop:disable Rails/SkipsModelValidations -- raw data
      expect(described_class.report["checks"]["unknown_line_item_types"]).to eq(0)

      PaymentLine.where(payment: payment).update_all(item_type: "Order") # rubocop:disable Rails/SkipsModelValidations -- raw data
      expect(described_class.report["checks"]["unknown_line_item_types"]).to eq(1)
    end

    it "checks session counters per formula duration, like Admin::HealthReport" do
      create(:contribution, contribution_formula: create(:contribution_formula, :annual))
      create(:contribution, contribution_formula: create(:contribution_formula, :day))
      expect(described_class.report["checks"]).to include(
        "unlimited_with_sessions_remaining" => 0, "day_pass_invalid_sessions" => 0, "pack10_without_sessions_remaining" => 0
      )

      Contribution.joins(:contribution_formula).where(contribution_formulas: { duration: :annual })
                  .update_all(sessions_remaining: 3) # rubocop:disable Rails/SkipsModelValidations -- raw data
      Contribution.joins(:contribution_formula).where(contribution_formulas: { duration: :day })
                  .update_all(sessions_remaining: 4) # rubocop:disable Rails/SkipsModelValidations -- raw data
      expect(described_class.report["checks"]).to include("unlimited_with_sessions_remaining" => 1, "day_pass_invalid_sessions" => 1)
    end
  end

  describe ".problems" do
    let(:before) do
      {
        "sqlite_integrity" => "ok", "foreign_key_violations" => 0,
        "tables" => { "payments" => 10, "people" => 5, "legacy" => 3 },
        "checks" => { "payments_without_lines" => 0, "legacy_donation_lines" => 2, "pack10_without_sessions_remaining" => "skipped" }
      }
    end

    def after(**changes)
      before.merge(changes.transform_keys(&:to_s))
    end

    it "accepts unchanged data, new tables and new rows" do
      grown = after(tables: { "payments" => 12, "people" => 5, "legacy" => 3, "new_table" => 4 })

      expect(described_class.problems(before, grown)).to be_empty
    end

    it "reports lost rows and a table that disappeared with data" do
      shrunk = after(tables: { "payments" => 7, "people" => 5 })

      expect(described_class.problems(before, shrunk)).to contain_exactly(
        "table payments lost rows: 10 -> 7", "table legacy disappeared (3 rows)"
      )
    end

    it "reports an anomaly that appears or grows, not one that stays or shrinks" do
      checks = { "payments_without_lines" => 3, "legacy_donation_lines" => 1, "pack10_without_sessions_remaining" => 4 }

      expect(described_class.problems(before, after(checks: checks))).to contain_exactly(
        "check payments_without_lines: 0 -> 3", "check pack10_without_sessions_remaining: n/a -> 4"
      )
    end

    it "reports SQLite corruption and new foreign key violations" do
      broken = after(sqlite_integrity: "row 3 missing from index", foreign_key_violations: 2)

      expect(described_class.problems(before, broken)).to contain_exactly(
        "sqlite integrity: row 3 missing from index", "foreign key violations: 0 -> 2"
      )
    end
  end
end
