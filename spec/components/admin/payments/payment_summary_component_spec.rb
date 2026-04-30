# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Payments::PaymentSummaryComponent, type: :component do
  let(:payments_relation) { Payment.all }

  it "revenue matches total_amount (donations are already inside payment totals)" do
    component = described_class.new(
      payments: payments_relation,
      total_amount: 10_000,
      total_donation: 3_000
    )

    expect(component.send(:total_revenue)).to eq(10_000)
    expect(component.send(:total_revenue)).not_to eq(10_000 + 3_000)
  end
end
