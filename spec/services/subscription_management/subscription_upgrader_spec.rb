require 'rails_helper'

RSpec.describe SubscriptionManagement::SubscriptionUpgrader do
  let(:person) { create(:person, :with_circus_membership) }
  let(:admin_user) { create(:user, :admin, person: create(:person)) }
  let(:pack_plan) { create(:subscription_plan, :pack10, price_cents: 10_000) }
  let(:trimester_plan) { create(:subscription_plan, :trimester, price_cents: 30_000) }
  let(:annual_plan) { create(:subscription_plan, :annual, price_cents: 90_000) }
  let(:pack_book) { create(:book_of_entry, person: person, subscription_plan: pack_plan, status: :active, sessions_remaining: 8) }

  describe "#call" do
    context "pack10 upgrade" do
      it "suspends pack and charges full price" do
        params = {
          person: person,
          from_book_id: pack_book.id,
          to_plan_id: trimester_plan.id,
          payment_method: "cash",
          recorded_by_id: admin_user.id
        }

        result = described_class.new(params).call

        expect(result.success?).to be true
        expect(pack_book.reload.status).to eq("suspended")
        expect(result.payment.total_cents).to eq(trimester_plan.price_cents)
        expect(result.credit_applied).to eq(0)
      end
    end

    context "trimester to annual" do
      let(:trimester_book) { create(:book_of_entry, person: person, subscription_plan: trimester_plan, status: :active, purchased_at: 15.days.ago, sessions_remaining: nil) }

      it "applies prorated credit" do
        params = {
          person: person,
          from_book_id: trimester_book.id,
          to_plan_id: annual_plan.id,
          payment_method: "cash",
          recorded_by_id: admin_user.id
        }

        result = described_class.new(params).call

        expect(result.success?).to be true
        expect(result.credit_applied).to be > 0
        expect(result.payment.total_cents).to eq(0)
      end
    end

    context "invalid upgrade" do
      it "rejects day plan target" do
        day_plan = create(:subscription_plan, :day)
        params = {
          person: person,
          from_book_id: pack_book.id,
          to_plan_id: day_plan.id,
          payment_method: "cash",
          recorded_by_id: admin_user.id
        }

        result = described_class.new(params).call
        expect(result.success?).to be false
        expect(result.message).to include("non autorisé")
      end

      it "fails when book not found" do
        params = { person: person, from_book_id: 999_999, to_plan_id: trimester_plan.id, payment_method: "cash", recorded_by_id: admin_user.id }
        result = described_class.new(params).call
        expect(result.success?).to be false
      end
    end

    context "permissions" do
      it "allows volunteer (permission enforced in model)" do
        volunteer = create(:user, :volunteer, person: create(:person))
        params = { person: person, from_book_id: pack_book.id, to_plan_id: trimester_plan.id, payment_method: "cash", recorded_by_id: volunteer.id }

        result = described_class.new(params).call
        expect(result.success?).to be true
      end
    end

    context "instrumentation" do
      it "fires subscription.upgraded" do
        params = { person: person, from_book_id: pack_book.id, to_plan_id: trimester_plan.id, payment_method: "cash", recorded_by_id: admin_user.id }

        expect {
          described_class.new(params).call
        }.to instrument("subscription.upgraded")
      end
    end
  end
end

