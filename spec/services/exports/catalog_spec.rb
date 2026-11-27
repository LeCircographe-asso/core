# frozen_string_literal: true

require "rails_helper"

RSpec.describe Exports::Catalog do
  def rows(export)
    CSV.parse(export.to_csv.delete_prefix(Exports::Base::BOM), headers: true)
  end

  # Header contract: changing these lists is a breaking change for downstream
  # consumers. Append only; anything else must bump `export_version`.
  describe "header contract" do
    {
      Exports::PaymentLines => [ 1, %w[
        payment_line_id payment_uuid paid_at payment_status payment_method payment_total_euros
        line_type line_label line_amount_euros
        beneficiary_person_id beneficiary_member_number beneficiary_last_name beneficiary_first_name
        payer_person_id payer_member_number payer_last_name payer_first_name
        recorded_by_user_id offer_reason anonymized
      ] ],
      Exports::Memberships => [ 1, %w[
        membership_id person_id member_number last_name first_name
        membership_type category status started_at ended_at first_joined_at created_at
      ] ],
      Exports::Contributions => [ 1, %w[
        contribution_id person_id member_number last_name first_name
        formula duration status purchased_at expires_at sessions_remaining suspended_at suspended_reason
      ] ],
      Exports::Attendances => [ 1, %w[
        attendance_id date person_id member_number last_name first_name
        attendance_list_id list_name list_type contribution_id formula
      ] ]
    }.each do |export, (version, headers)|
      it "locks #{export.key} v#{version} headers" do
        expect(export.version).to eq(version)
        expect(export.headers).to eq(headers)
      end
    end

    it "registers every export" do
      expect(described_class::ALL.map(&:key)).to eq(%w[payment_lines memberships contributions attendances])
    end
  end

  describe ".fetch" do
    it "raises not found for an unknown key" do
      expect { described_class.fetch("people; DROP") }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe Exports::PaymentLines do
    let(:payer) { create(:person, first_name: "Paula", last_name: "Payer") }
    let(:beneficiary) { create(:person, first_name: "Bea", last_name: "Neficiary") }
    let(:payment) { create(:payment, :success, person: payer, total_cents: 4250) }

    it "exports one row per line with payer and beneficiary" do
      create(:payment_line, payment:, person: beneficiary, amount_cents: 4250)

      row = rows(described_class.new).first

      expect(row["payment_uuid"]).to eq(payment.uuid)
      expect(row["payment_total_euros"]).to eq("42.50")
      expect(row["beneficiary_last_name"]).to eq("Neficiary")
      expect(row["payer_last_name"]).to eq("Payer")
      expect(row["anonymized"]).to eq("false")
    end

    it "falls back to the payer when the line has no beneficiary" do
      create(:payment_line, payment:, person: nil)

      expect(rows(described_class.new).first["beneficiary_person_id"]).to eq(payer.id.to_s)
    end
  end

  describe "period filter" do
    it "keeps both bounds inclusive on date columns" do
      inside = [ create(:attendance, date: Date.new(2026, 1, 1)), create(:attendance, date: Date.new(2026, 1, 31)) ]
      create(:attendance, date: Date.new(2026, 2, 1))

      export = Exports::Attendances.new(from: "2026-01-01", to: "2026-01-31")

      expect(rows(export).map { |row| row["attendance_id"].to_i }).to match_array(inside.map(&:id))
      expect(export.row_count).to eq(2)
      expect(export.filename).to eq("attendances_v1_2026-01-01_2026-01-31_#{Date.current.iso8601}.csv")
    end

    it "covers whole days on datetime columns and accepts open bounds" do
      kept = create(:contribution, purchased_at: Time.zone.local(2026, 3, 15, 23, 30))
      create(:contribution, purchased_at: Time.zone.local(2026, 3, 14, 23, 59))

      ids = rows(Exports::Contributions.new(from: "2026-03-15")).map { |row| row["contribution_id"].to_i }

      expect(ids).to eq([ kept.id ])
    end

    it "ignores malformed dates" do
      create(:attendance)

      export = Exports::Attendances.new(from: "not-a-date")

      expect(export.from).to be_nil
      expect(rows(export).size).to eq(1)
    end
  end

  describe "spreadsheet safety" do
    it "neutralizes formula-like values and prefixes a BOM" do
      create(:attendance, person: create(:person, last_name: "=HYPERLINK(\"http://evil\")"))

      csv = Exports::Attendances.new.to_csv

      expect(csv).to start_with(Exports::Base::BOM)
      expect(rows(Exports::Attendances.new).first["last_name"]).to eq("'=HYPERLINK(\"http://evil\")")
    end
  end
end
