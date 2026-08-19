# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::DashboardStatisticsService do
  describe "#call" do
    it "counts active memberships by category, matching MembershipType#category (not #name)" do
      create(:membership, :active, membership_type: create(:membership_type, :basic))
      create(:membership, :active, membership_type: create(:membership_type, :circus))
      create(:membership, :active, membership_type: create(:membership_type, :circus))
      create(:membership, :expired, started_at: 2.days.ago, membership_type: create(:membership_type, :circus))

      stats = described_class.new.call

      expect(stats[:basic_memberships]).to eq(1)
      expect(stats[:circus_memberships]).to eq(2)
    end
  end
end
