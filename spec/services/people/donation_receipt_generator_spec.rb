# frozen_string_literal: true

require "rails_helper"

RSpec.describe People::DonationReceiptGenerator do
  let(:payment) { create(:payment, status: :success, payment_method: :cheque) }
  let(:donation_line) do
    create(:payment_line, payment: payment, item_type: "Donation", item_id: payment.id, amount_cents: 1234, description: "Don libre")
  end
  let(:donation_receipt) do
    People::DonationReceiptIssuer.new(payment_line: donation_line, issued_at: Time.zone.local(2026, 3, 1)).call.donation_receipt
  end

  describe "#call" do
    it "renders a valid PDF binary" do
      pdf = described_class.new(donation_receipt: donation_receipt).call

      expect(pdf).to be_a(String)
      expect(pdf.byteslice(0, 5)).to eq("%PDF-")
    end

    it "raises when donation_receipt is missing" do
      expect { described_class.new.call }.to raise_error(ArgumentError)
    end
  end
end
