require 'rails_helper'

RSpec.describe SubscriptionManagement::SubscriptionCreator do
  let(:person) { create(:person) }
  let(:membership_type) { create(:membership_type, category: :circus) }
  let(:membership) { create(:membership, person: person, membership_type: membership_type, status: :active) }
  let(:subscription_plan) { create(:subscription_plan, :pack10) }
  let(:admin_user) { create(:user, system_role: :admin) }
  
  before do
    membership # Ensure membership is created
  end

  describe "#call" do
    context "with valid attributes" do
      let(:params) do
        {
          person: person,
          subscription_plan_id: subscription_plan.id,
          payment_method: "cash",
          recorded_by_id: admin_user.id,
          record_attendance: false
        }
      end

      it "creates subscription successfully" do
        creator = described_class.new(params)
        result = creator.call

        expect(result.success?).to be true
        expect(result.book_of_entry).to be_present
        expect(result.payment).to be_present
      end

      it "creates payment with correct amount" do
        creator = described_class.new(params)
        result = creator.call

        expect(result.payment.total_cents).to eq(subscription_plan.price_cents)
      end

      it "creates book_of_entry with active status" do
        creator = described_class.new(params)
        result = creator.call

        expect(result.book_of_entry.status).to eq("active")
      end
    end

    context "with custom amount" do
      let(:params) do
        {
          person: person,
          subscription_plan_id: subscription_plan.id,
          payment_method: "offered",
          recorded_by_id: admin_user.id,
          record_attendance: false,
          custom_amount_cents: 1500,
          offer_reason: "Test offer"
        }
      end

      it "creates payment with custom amount" do
        creator = described_class.new(params)
        result = creator.call
        
        expect(result.success?).to be true
        expect(result.payment).to be_present
        expect(result.payment.total_cents).to eq(1500)
      end
    end

    context "with invalid attributes" do
      it "returns failure when person is missing" do
        params = { subscription_plan_id: subscription_plan.id, payment_method: "cash", recorded_by_id: admin_user.id }
        creator = described_class.new(params)
        
        result = creator.call
        expect(result.success?).to be false
        expect(result.message).to include("Invalid data")
      end

      it "returns failure when subscription_plan_id is missing" do
        params = { person: person, payment_method: "cash", recorded_by_id: admin_user.id }
        creator = described_class.new(params)
        
        result = creator.call
        expect(result.success?).to be false
      end

      it "returns failure when recorded_by_id is missing" do
        params = { person: person, subscription_plan_id: subscription_plan.id, payment_method: "cash" }
        creator = described_class.new(params)
        
        result = creator.call
        expect(result.success?).to be false
      end
    end

    context "with record not found" do
      it "returns failure when subscription_plan doesn't exist" do
        params = { person: person, subscription_plan_id: 99999, payment_method: "cash", recorded_by_id: admin_user.id }
        creator = described_class.new(params)
        
        result = creator.call
        expect(result.success?).to be false
        expect(result.message).to include("Record not found")
      end

      it "returns failure when user doesn't exist" do
        params = { person: person, subscription_plan_id: subscription_plan.id, payment_method: "cash", recorded_by_id: 99999 }
        creator = described_class.new(params)
        
        result = creator.call
        expect(result.success?).to be false
        expect(result.message).to include("Record not found")
      end
    end

    context "with person without circus membership" do
      let(:person_without_circus) { create(:person) }
      let!(:basic_membership) { create(:membership, person: person_without_circus, membership_type: create(:membership_type, category: :basic), status: :active) }
      
      it "returns failure when person cannot buy subscription plans" do
        params = {
          person: person_without_circus,
          subscription_plan_id: subscription_plan.id,
          payment_method: "cash",
          recorded_by_id: admin_user.id
        }
        creator = described_class.new(params)
        
        result = creator.call
        expect(result.success?).to be false
        expect(result.message).to include("adhésion Cirque")
      end
    end

    context "instrumentation" do
      let(:params) do
        {
          person: person,
          subscription_plan_id: subscription_plan.id,
          payment_method: "cash",
          recorded_by_id: admin_user.id,
          record_attendance: false
        }
      end

      it "fires subscription.created notification" do
        expect {
          creator = described_class.new(params)
          creator.call
        }.to instrument("subscription.created")
      end
    end
  end
end

