# frozen_string_literal: true

require "rails_helper"

RSpec.describe People::PaymentRecorder do
  describe "#call" do
    let(:person) { create(:person) }
    let(:admin_user) { create(:user, :admin) }
    let(:membership) { create(:membership, person: person) }
    let(:contribution_formula) { create(:contribution_formula, :pack10) }

    it "creates a payment with multiple lines when the total matches" do
      result = described_class.new(
        person: person,
        recorded_by: admin_user,
        payment_method: "cash",
        total_cents: 3_500,
        payment_lines: [
          { item_type: "Membership", item_id: membership.id, amount_cents: 1_000, description: "Adhésion" },
          { item_type: "ContributionFormula", item_id: contribution_formula.id, amount_cents: 2_500, description: "Pack 10" }
        ]
      ).call

      expect(result.success?).to be(true)
      expect(result.payment.total_cents).to eq(3_500)
      expect(result.payment.payment_lines.pluck(:item_type, :amount_cents)).to contain_exactly(
        [ "Membership", 1_000 ],
        [ "ContributionFormula", 2_500 ]
      )
    end

    it "persists an explicit person_id per line, distinct from the payer" do
      beneficiary = create(:person)

      result = described_class.new(
        person: person,
        recorded_by: admin_user,
        payment_method: "cash",
        total_cents: 2_500,
        payment_lines: [
          { item_type: "ContributionFormula", item_id: contribution_formula.id, person_id: beneficiary.id, amount_cents: 2_500, description: "Pack 10" }
        ]
      ).call

      expect(result.success?).to be(true)
      expect(result.payment.person).to eq(person)
      expect(result.payment.payment_lines.first.person).to eq(beneficiary)
    end

    it "logs a create audit entry with the line/beneficiary detail" do
      beneficiary = create(:person)

      expect do
        described_class.new(
          person: person,
          recorded_by: admin_user,
          payment_method: "cash",
          total_cents: 2_500,
          payment_lines: [
            { item_type: "ContributionFormula", item_id: contribution_formula.id, person_id: beneficiary.id, amount_cents: 2_500, description: "Pack 10" }
          ]
        ).call
      end.to change(PaymentAuditLog, :count).by(1)

      audit_log = PaymentAuditLog.last
      expect(audit_log.action).to eq("create")
      change_data = JSON.parse(audit_log.change_data)
      expect(change_data["lines"].sole["person_id"]).to eq(beneficiary.id)
      expect(change_data["lines"].sole["amount_cents"]).to eq(2_500)
    end

    it "falls back to the payer's id when a line omits person_id" do
      result = described_class.new(
        person: person,
        recorded_by: admin_user,
        payment_method: "cash",
        total_cents: 1_000,
        payment_lines: [
          { item_type: "Membership", item_id: membership.id, amount_cents: 1_000, description: "Adhésion" }
        ]
      ).call

      expect(result.success?).to be(true)
      expect(result.payment.payment_lines.first.person).to eq(person)
    end

    it "rejects a payment when line totals do not match the payment total" do
      result = described_class.new(
        person: person,
        recorded_by: admin_user,
        payment_method: "cash",
        total_cents: 3_000,
        payment_lines: [
          { item_type: "Membership", item_id: membership.id, amount_cents: 1_000, description: "Adhésion" },
          { item_type: "ContributionFormula", item_id: contribution_formula.id, amount_cents: 1_500, description: "Pack 10" }
        ]
      ).call

      expect(result.success?).to be(false)
      expect(result.message).to include("La somme des lignes")
      expect(Payment.count).to eq(0)
    end

    it "links donation lines back to the created payment" do
      result = described_class.new(
        person: person,
        recorded_by: admin_user,
        payment_method: "cash",
        total_cents: 700,
        payment_lines: [
          { item_type: "Donation", amount_cents: 700, description: "Donation" }
        ]
      ).call

      expect(result.success?).to be(true)

      line = result.payment.payment_lines.first
      expect(line.item_type).to eq("Donation")
      expect(line.item_id).to eq(result.payment.id)
    end

    it "falls back to Current.user when recorded_by is omitted" do
      Current.session = admin_user.sessions.create!(user_agent: "RSpec", ip_address: "127.0.0.1")

      result = described_class.new(
        person: person,
        payment_method: "cash",
        total_cents: 700,
        payment_lines: [
          { item_type: "Donation", amount_cents: 700, description: "Donation" }
        ]
      ).call

      expect(result.success?).to be(true)
      expect(result.payment.recorded_by).to eq(admin_user)
    ensure
      Current.session&.destroy
      Current.session = nil
    end

    it "strips the offer reason before persisting an offered payment" do
      result = described_class.new(
        person: person,
        recorded_by: admin_user,
        payment_method: "offered",
        total_cents: 0,
        offer_reason: "  Solidarity for volunteer work  ",
        payment_lines: [
          { item_type: "Donation", amount_cents: 0, description: "Offert" }
        ]
      ).call

      expect(result.success?).to be(true)
      expect(result.payment.offer_reason).to eq("Solidarity for volunteer work")
    end

    it "rejects an offered payment without an offer reason" do
      result = described_class.new(
        person: person,
        recorded_by: admin_user,
        payment_method: "offered",
        total_cents: 0,
        payment_lines: [
          { item_type: "Donation", amount_cents: 0, description: "Offert" }
        ]
      ).call

      expect(result.success?).to be(false)
      expect(result.message).to include("Offer reason")
    end
  end
end
