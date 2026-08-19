# frozen_string_literal: true

require "rails_helper"

RSpec.describe ExceptionalClosure do
  describe ".current" do
    it "creates and returns a singleton row when none exists" do
      expect { described_class.current }.to change(described_class, :count).by(1)
    end

    it "returns the same row on subsequent calls" do
      first = described_class.current

      expect(described_class.current).to eq(first)
      expect(described_class.count).to eq(1)
    end
  end

  describe "#in_effect?" do
    it "is false when inactive" do
      closure = described_class.new(active: false)

      expect(closure.in_effect?).to be false
    end

    it "is true when active with no end date" do
      closure = described_class.new(active: true, ends_on: nil)

      expect(closure.in_effect?).to be true
    end

    it "is true when active and the end date is today or later" do
      closure = described_class.new(active: true, ends_on: Date.current)

      expect(closure.in_effect?).to be true
    end

    it "is false when active but the end date has passed" do
      closure = described_class.new(active: true, ends_on: Date.current - 1)

      expect(closure.in_effect?).to be false
    end
  end
end
