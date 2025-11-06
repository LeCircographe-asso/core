require 'rails_helper'

RSpec.describe SubscriptionManagement::SubscriptionCreator do
  let(:person) { create(:person, :with_circus_membership) }
  let(:subscription_plan) { create(:subscription_plan, :pack10) }
  let(:admin_user) { create(:user, :admin, person: create(:person)) }

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

      it "creates a pack10 book_of_entry without expiration" do
        result = described_class.new(params).call

        expect(result.book_of_entry.is_pack10?).to be true
        expect(result.book_of_entry.sessions_remaining).to eq(subscription_plan.sessions_count)
        expect(result.book_of_entry.expires_at).to be_nil
      end
    end

    context "with offered payment" do
      it "requires offer_reason" do
        creator = described_class.new(
          person: person,
          subscription_plan_id: subscription_plan.id,
          payment_method: "offered",
          recorded_by_id: admin_user.id
        )
        result = creator.call

        expect(result.success?).to be false
        expect(result.message).to include("raison doit être fournie")
      end

      it "succeeds for super_admin with offer_reason" do
        super_admin = create(:user, :super_admin, person: create(:person))
        creator = described_class.new(
          person: person,
          subscription_plan_id: subscription_plan.id,
          payment_method: "offered",
          recorded_by_id: super_admin.id,
          offer_reason: "Solidarity"
        )

        result = creator.call
        expect(result.success?).to be true
        expect(result.payment.total_cents).to eq(0)
      end
    end

    context "with invalid attributes" do
      it "returns failure when person is missing" do
        creator = described_class.new(
          subscription_plan_id: subscription_plan.id,
          payment_method: "cash",
          recorded_by_id: admin_user.id
        )

        result = creator.call
        expect(result.success?).to be false
        expect(result.message).to include("Invalid data")
      end

      it "returns failure when subscription_plan_id is missing" do
        creator = described_class.new(
          person: person,
          payment_method: "cash",
          recorded_by_id: admin_user.id
        )

        result = creator.call
        expect(result.success?).to be false
      end

      it "returns failure when recorded_by_id is missing" do
        creator = described_class.new(
          person: person,
          subscription_plan_id: subscription_plan.id,
          payment_method: "cash"
        )

        result = creator.call
        expect(result.success?).to be false
      end
    end

    context "with record not found" do
      it "returns failure when subscription_plan doesn't exist" do
        creator = described_class.new(
          person: person,
          subscription_plan_id: 999_999,
          payment_method: "cash",
          recorded_by_id: admin_user.id
        )

        result = creator.call
        expect(result.success?).to be false
        expect(result.message).to include("Record not found")
      end

      it "returns failure when user doesn't exist" do
        creator = described_class.new(
          person: person,
          subscription_plan_id: subscription_plan.id,
          payment_method: "cash",
          recorded_by_id: 999_999
        )

        result = creator.call
        expect(result.success?).to be false
        expect(result.message).to include("Record not found")
      end
    end

    context "with person without circus membership" do
      let(:basic_person) { create(:person) }
      let!(:basic_membership) { create(:membership, person: basic_person, membership_type: create(:membership_type, category: :basic), status: :active) }

      it "returns failure when person cannot buy subscription plans" do
        creator = described_class.new(
          person: basic_person,
          subscription_plan_id: subscription_plan.id,
          payment_method: "cash",
          recorded_by_id: admin_user.id
        )

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
          described_class.new(params).call
        }.to instrument("subscription.created")
      end
    end
  end
end

