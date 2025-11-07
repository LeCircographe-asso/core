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
end
