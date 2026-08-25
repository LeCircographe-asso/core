# frozen_string_literal: true

require "rails_helper"

RSpec.describe BugReportWidgetSetting, type: :model do
  describe ".current" do
    it "creates the singleton row on first access" do
      expect { described_class.current }.to change(described_class, :count).from(0).to(1)
    end

    it "returns the same row on subsequent calls" do
      first = described_class.current

      expect(described_class.current).to eq(first)
    end

    it "defaults to disabled" do
      expect(described_class.current).not_to be_enabled
    end
  end
end
