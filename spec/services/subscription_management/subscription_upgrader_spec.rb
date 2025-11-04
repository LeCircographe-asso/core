require 'rails_helper'

RSpec.describe SubscriptionManagement::SubscriptionUpgrader do
  let(:person) { create(:person) }
  let(:membership_type) { create(:membership_type, category: :circus) }
  let(:membership) { create(:membership, person: person, membership_type: membership_type, status: :active) }
  let(:from_plan) { create(:subscription_plan, :pack10, price_cents: 10000) }
  let(:to_plan) { create(:subscription_plan, :trimester, price_cents: 30000) }
  let(:admin_user) { create(:user, system_role: :admin) }
  let(:from_book) { create(:book_of_entry, person: person, subscription_plan: from_plan, status: :active) }
  
  before do
    membership # Ensure membership is created
  end

  describe "#call" do
    context "with valid attributes" do
      let(:params) do
        {
          person: person,
          from_book_id: from_book.id,
          to_plan_id: to_plan.id,
          payment_method: "cash",
          recorded_by_id: admin_user.id
        }
      end

      it "upgrades subscription successfully" do
        upgrader = described_class.new(params)
        result = upgrader.call

        expect(result.success?).to be true
        expect(result.book_of_entry).to be_present
        expect(result.payment).to be_present
      end

      it "applies credit from old subscription" do
        upgrader = described_class.new(params)
        result = upgrader.call

        expect(result.credit_applied).to be >= 0
      end

      it "suspends old book_of_entry" do
        upgrader = described_class.new(params)
        upgrader.call

        expect(from_book.reload.status).to eq("suspended")
      end
    end

    context "with invalid attributes" do
      it "returns failure when person is missing" do
        params = { from_book_id: from_book.id, to_plan_id: to_plan.id, payment_method: "cash", recorded_by_id: admin_user.id }
        upgrader = described_class.new(params)
        
        result = upgrader.call
        expect(result.success?).to be false
        expect(result.message).to include("Invalid data")
      end

      it "returns failure when from_book_id is missing" do
        params = { person: person, to_plan_id: to_plan.id, payment_method: "cash", recorded_by_id: admin_user.id }
        upgrader = described_class.new(params)
        
        result = upgrader.call
        expect(result.success?).to be false
      end

      it "returns failure when to_plan_id is missing" do
        params = { person: person, from_book_id: from_book.id, payment_method: "cash", recorded_by_id: admin_user.id }
        upgrader = described_class.new(params)
        
        result = upgrader.call
        expect(result.success?).to be false
      end
    end

    context "with record not found" do
      it "returns failure when from_book doesn't exist" do
        params = { person: person, from_book_id: 99999, to_plan_id: to_plan.id, payment_method: "cash", recorded_by_id: admin_user.id }
        upgrader = described_class.new(params)
        
        result = upgrader.call
        expect(result.success?).to be false
        expect(result.message).to include("Record not found")
      end

      it "returns failure when to_plan doesn't exist" do
        params = { person: person, from_book_id: from_book.id, to_plan_id: 99999, payment_method: "cash", recorded_by_id: admin_user.id }
        upgrader = described_class.new(params)
        
        result = upgrader.call
        expect(result.success?).to be false
        expect(result.message).to include("Record not found")
      end
    end

    context "with invalid upgrade path" do
      let(:invalid_plan) { create(:subscription_plan, :day) }
      
      it "returns failure when upgrade is not allowed" do
        params = {
          person: person,
          from_book_id: from_book.id,
          to_plan_id: invalid_plan.id,
          payment_method: "cash",
          recorded_by_id: admin_user.id
        }
        upgrader = described_class.new(params)
        
        result = upgrader.call
        expect(result.success?).to be false
        expect(result.message).to include("non autorisé")
      end
    end

    context "instrumentation" do
      let(:params) do
        {
          person: person,
          from_book_id: from_book.id,
          to_plan_id: to_plan.id,
          payment_method: "cash",
          recorded_by_id: admin_user.id
        }
      end

      it "fires subscription.upgraded notification" do
        expect {
          upgrader = described_class.new(params)
          upgrader.call
        }.to instrument("subscription.upgraded")
      end
    end
  end
end

