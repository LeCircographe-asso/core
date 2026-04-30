# frozen_string_literal: true

require "rails_helper"

RSpec.describe Donation do
  describe "polymorphic PaymentLine.item" do
    it "resolves donation lines to the parent Payment row via Donation class" do
      payment = create(:payment, :success)
      PaymentLine.create!(
        payment: payment,
        item_type: "Donation",
        item_id: payment.id,
        amount_cents: 100,
        description: "Don libre"
      )

      line = PaymentLine.includes(:item).find_by!(payment: payment, item_type: "Donation")

      expect(line.item).to be_a(described_class)
      expect(line.item.id).to eq(payment.id)
      expect(line.item.total_cents).to eq(payment.total_cents)
    end
  end
end
