# frozen_string_literal: true

require "rails_helper"

RSpec.describe DonationReceipt, type: :model do
  let(:payment) { create(:payment, status: :success) }
  let(:donation_line) do
    create(:payment_line, payment: payment, item_type: "Donation", item_id: payment.id, amount_cents: 500, description: "Don libre")
  end

  let(:base_attrs) { { number: "2026-001", issued_at: Time.current, issuer: "Le Circographe", donor_name: "Jean Dupont" } }

  it "is valid with number, issued_at, issuer, donor_name and a donation payment_line" do
    receipt = DonationReceipt.new(payment_line: donation_line, **base_attrs)

    expect(receipt).to be_valid
  end

  it "is invalid without number, issued_at, issuer or donor_name" do
    receipt = DonationReceipt.new(payment_line: donation_line)

    expect(receipt).not_to be_valid
    expect(receipt.errors[:number]).to be_present
    expect(receipt.errors[:issued_at]).to be_present
    expect(receipt.errors[:issuer]).to be_present
    expect(receipt.errors[:donor_name]).to be_present
  end

  it "rejects a payment_line that is not a donation" do
    membership_line = create(:payment_line, payment: payment, item_type: "MembershipType")
    receipt = DonationReceipt.new(payment_line: membership_line, **base_attrs)

    expect(receipt).not_to be_valid
    expect(receipt.errors[:payment_line]).to be_present
  end

  it "enforces a unique receipt number" do
    DonationReceipt.create!(payment_line: donation_line, **base_attrs)
    other_line = create(:payment_line, payment: payment, item_type: "Donation", item_id: create(:payment, status: :success).id)

    duplicate = DonationReceipt.new(payment_line: other_line, **base_attrs)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:number]).to be_present
  end

  it "enforces at most one receipt per payment_line" do
    DonationReceipt.create!(payment_line: donation_line, **base_attrs)

    expect {
      DonationReceipt.create!(payment_line: donation_line, **base_attrs.merge(number: "2026-002"))
    }.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
