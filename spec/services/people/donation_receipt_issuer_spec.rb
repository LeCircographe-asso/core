# frozen_string_literal: true

require "rails_helper"

RSpec.describe People::DonationReceiptIssuer do
  let(:payment) { create(:payment, status: :success) }
  let(:donation_line) do
    create(:payment_line, payment: payment, item_type: "Donation", item_id: payment.id, amount_cents: 500, description: "Don libre")
  end

  describe "#call" do
    it "issues a receipt with a year-prefixed sequential number and a snapshotted issuer" do
      result = described_class.new(payment_line: donation_line, issued_at: Time.zone.local(2026, 3, 1)).call

      expect(result.success?).to be(true)
      expect(result.donation_receipt.number).to eq("2026-001")
      expect(result.donation_receipt.issuer).to eq("Le Circographe")
      expect(result.donation_receipt.issued_at).to eq(Time.zone.local(2026, 3, 1))
    end

    it "increments the sequence for the same year" do
      other_payment = create(:payment, status: :success)
      other_line = create(:payment_line, payment: other_payment, item_type: "Donation", item_id: other_payment.id)
      described_class.new(payment_line: other_line, issued_at: Time.zone.local(2026, 1, 5)).call

      result = described_class.new(payment_line: donation_line, issued_at: Time.zone.local(2026, 6, 1)).call

      expect(result.donation_receipt.number).to eq("2026-002")
    end

    it "restarts the sequence on a new calendar year" do
      other_payment = create(:payment, status: :success)
      other_line = create(:payment_line, payment: other_payment, item_type: "Donation", item_id: other_payment.id)
      described_class.new(payment_line: other_line, issued_at: Time.zone.local(2025, 12, 31)).call

      result = described_class.new(payment_line: donation_line, issued_at: Time.zone.local(2026, 1, 2)).call

      expect(result.donation_receipt.number).to eq("2026-001")
    end

    it "reads the issuer from ASSOCIATION_RECEIPT_ISSUER when set" do
      original = ENV["ASSOCIATION_RECEIPT_ISSUER"]
      ENV["ASSOCIATION_RECEIPT_ISSUER"] = "Le Circographe - 12 rue du Cirque, 75000 Paris"

      result = described_class.new(payment_line: donation_line).call

      expect(result.donation_receipt.issuer).to eq("Le Circographe - 12 rue du Cirque, 75000 Paris")
    ensure
      ENV["ASSOCIATION_RECEIPT_ISSUER"] = original
    end

    it "fires instrumentation" do
      issuer = described_class.new(payment_line: donation_line)

      expect { issuer.call }.to instrument("donation.receipt_issued")
    end

    it "fails when the payment_line is not a donation" do
      membership_line = create(:payment_line, payment: payment, item_type: "MembershipType")

      result = described_class.new(payment_line: membership_line).call

      expect(result.success?).to be(false)
      expect(result.message).to include("not a donation")
    end

    it "fails when a receipt already exists for the payment_line" do
      described_class.new(payment_line: donation_line).call

      result = described_class.new(payment_line: donation_line).call

      expect(result.success?).to be(false)
      expect(result.message).to include("already exists")
      expect(result.donation_receipt).to be_present
    end

    it "fails when payment_line is missing" do
      result = described_class.new.call

      expect(result.success?).to be(false)
      expect(result.message).to include("Invalid receipt data")
    end

    it "fails when payment_line_id does not resolve" do
      result = described_class.new(payment_line_id: 999_999).call

      expect(result.success?).to be(false)
      expect(result.message).to include("not found")
    end
  end
end
