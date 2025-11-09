require 'rails_helper'

RSpec.describe AccountClaim, type: :model do
  let(:person) { create(:person) }
  let(:user) { create(:user) }

  describe "associations" do
    it { should belong_to(:person) }
    it { should belong_to(:user).optional }
  end

  describe "enums" do
    it "defines status enum" do
      expect(AccountClaim.statuses).to eq({
        'pending' => 'pending',
        'confirmed' => 'confirmed',
        'rejected' => 'rejected',
        'expired' => 'expired'
      })
    end
  end

  describe "validations" do
    it "validates presence of expires_at" do
      claim = build(:account_claim, expires_at: nil)
      expect(claim).not_to be_valid
      expect(claim.errors[:expires_at]).to include("can't be blank")
    end

    it "auto-generates unique confirmation_token" do
      claim1 = create(:account_claim)
      claim2 = create(:account_claim)

      expect(claim1.confirmation_token).to be_present
      expect(claim2.confirmation_token).to be_present
      expect(claim1.confirmation_token).not_to eq(claim2.confirmation_token)
    end
  end

  describe "scopes" do
    let!(:active_claim) { create(:account_claim, status: :pending, expires_at: 2.days.from_now) }
    let!(:expired_pending_claim) { create(:account_claim, status: :pending, expires_at: 1.day.ago) }
    let!(:confirmed_claim) { create(:account_claim, status: :confirmed, expires_at: 2.days.from_now) }
    let!(:rejected_claim) { create(:account_claim, status: :rejected, expires_at: 2.days.from_now) }

    describe ".active" do
      it "returns only pending claims that haven't expired" do
        active_claims = AccountClaim.active

        expect(active_claims).to include(active_claim)
        expect(active_claims).not_to include(expired_pending_claim, confirmed_claim, rejected_claim)
      end
    end
  end

  describe "#expired?" do
    it "returns true when expires_at is in the past" do
      claim = create(:account_claim, status: :pending, expires_at: 1.day.ago)
      expect(claim.expired?).to be true
    end

    it "returns false when expires_at is in the future" do
      claim = create(:account_claim, status: :pending, expires_at: 1.day.from_now)
      expect(claim.expired?).to be false
    end
  end

  describe "lifecycle" do
    it "creates with pending status by default" do
      claim = create(:account_claim)
      expect(claim.status).to eq("pending")
    end

    it "can be confirmed" do
      claim = create(:account_claim)
      claim.update!(status: :confirmed)
      expect(claim.confirmed?).to be true
    end

    it "can be rejected" do
      claim = create(:account_claim)
      claim.update!(status: :rejected)
      expect(claim.rejected?).to be true
    end

    it "can be marked with expired status" do
      claim = create(:account_claim)
      claim.update!(status: :expired)
      expect(claim.status).to eq("expired")
    end
  end

  describe "Statusable concern methods" do
    let(:claim) { create(:account_claim, status: :pending) }

    describe "#status_humanized" do
      it "returns humanized status" do
        expect(claim.status_humanized).to be_present
      end

      it "returns humanized status for confirmed" do
        confirmed_claim = create(:account_claim, status: :confirmed)
        expect(confirmed_claim.status_humanized).to be_present
      end

      it "returns humanized status for rejected" do
        rejected_claim = create(:account_claim, status: :rejected)
        expect(rejected_claim.status_humanized).to be_present
      end
    end

    describe "#pending?" do
      it "returns true for pending status" do
        expect(claim.pending?).to be true
      end
    end

    describe "#status_badge_class" do
      it "returns badge class for pending status" do
        expect(claim.status_badge_class).to eq("bg-yellow-100 text-yellow-800")
      end

      it "returns badge class for confirmed status" do
        confirmed_claim = create(:account_claim, status: :confirmed)
        expect(confirmed_claim.status_badge_class).to be_present
      end
    end
  end

  describe "Dateable concern methods" do
    let(:claim) { create(:account_claim, expires_at: Date.current.end_of_week.beginning_of_day + 12.hours) }

    describe "#formatted_date" do
      it "formats expires_at date" do
        formatted = claim.formatted_date(:expires_at)
        expect(formatted).to match(/\d{2}\/\d{2}\/\d{4}/)
      end
    end

    describe "#formatted_datetime" do
      it "formats expires_at datetime" do
        formatted = claim.formatted_datetime(:expires_at)
        expect(formatted).to match(/\d{2}\/\d{2}\/\d{4} à \d{2}:\d{2}/)
      end
    end

    describe "#today?" do
      it "returns true for claim expiring today" do
        today_claim = create(:account_claim, expires_at: Date.current.beginning_of_day + 12.hours)
        expect(today_claim.today?(:expires_at)).to be true
      end

      it "returns false for claim expiring this week (but not today)" do
        other_day = (Date.current.beginning_of_week..Date.current.end_of_week).to_a.find { |d| d != Date.current }
        not_today_claim = create(:account_claim, expires_at: other_day.beginning_of_day + 12.hours)
        expect(not_today_claim.today?(:expires_at)).to be false
      end
    end

    describe "#this_week?" do
      it "returns true for claim expiring this week" do
        expect(claim.this_week?(:expires_at)).to be true
      end
    end

    describe "#this_month?" do
      it "returns true for claim expiring this month" do
        expect(claim.this_month?(:expires_at)).to be true
      end
    end

    describe "#expired? (custom method - checks expires_at, not status)" do
      it "overrides Statusable expired? method" do
        # AccountClaim's expired? checks expires_at date, not status
        future_claim = create(:account_claim, expires_at: 1.week.from_now, status: :pending)
        expect(future_claim.expired?).to be false

        past_claim = create(:account_claim, expires_at: 1.day.ago, status: :pending)
        expect(past_claim.expired?).to be true
      end
    end
  end
end
