# frozen_string_literal: true

require "rails_helper"

RSpec.describe People::ContributionPayloadBuilder do
  describe ".call" do
    it "builds payload for day contributions" do
      formula = create(:contribution_formula, :day)

      payload = described_class.call(formula, reference_date: Date.new(2026, 5, 1))

      expect(payload[:sessions_remaining]).to eq(1)
      expect(payload[:expires_at]).to eq(Time.zone.local(2026, 5, 1).end_of_day)
    end

    it "builds payload for trimester contributions" do
      formula = create(:contribution_formula, :trimester, validity_days: 90)

      payload = described_class.call(formula, reference_date: Date.new(2026, 1, 15))

      expect(payload[:sessions_remaining]).to be_nil
      expect(payload[:expires_at]).to eq(Date.new(2026, 4, 15))
    end

    it "builds payload for pack10 contributions" do
      formula = create(:contribution_formula, duration: "pack10", sessions_count: 12, validity_days: 1)

      payload = described_class.call(formula)

      expect(payload[:sessions_remaining]).to eq(12)
      expect(payload[:expires_at]).to be_nil
    end

    it "builds payload for annual contributions" do
      formula = create(:contribution_formula, duration: "annual", validity_days: 365)

      payload = described_class.call(formula, reference_date: Date.new(2026, 1, 15))

      expect(payload[:sessions_remaining]).to be_nil
      expect(payload[:expires_at]).to eq(Date.new(2027, 1, 15))
    end
  end
end
