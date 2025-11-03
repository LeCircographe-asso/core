require 'rails_helper'

RSpec.describe MembershipManagement::MembershipCreator do
  let(:person) { create(:person) }
  let(:membership_type) { create(:membership_type) }
  let(:admin_user) { create(:user, system_role: :admin) }

  describe "#call" do
    context "with valid attributes" do
      let(:params) do
        {
          person: person,
          membership_type_id: membership_type.id,
          payment_method: "cash",
          recorded_by_id: admin_user.id
        }
      end

      it "creates membership successfully" do
        creator = described_class.new(params)
        result = creator.call

        expect(result.success?).to be true
        expect(result.membership).to be_present
        expect(result.payment).to be_present
      end

      it "creates payment with correct amount" do
        creator = described_class.new(params)
        result = creator.call

        expect(result.payment.total_cents).to eq(membership_type.price_cents)
      end

      it "creates membership with active status" do
        creator = described_class.new(params)
        result = creator.call

        expect(result.membership.status).to eq("active")
      end
    end

    context "with custom amount" do
      let(:params) do
        {
          person: person,
          membership_type_id: membership_type.id,
          payment_method: "offered",
          recorded_by_id: admin_user.id,
          custom_amount_cents: 2500,
          offer_reason: "Test offer"
        }
      end

      it "creates payment with custom amount" do
        creator = described_class.new(params)
        result = creator.call
        
        expect(result.success?).to be true
        expect(result.payment).to be_present
        expect(result.payment.total_cents).to eq(2500)
      end
    end

    context "with invalid attributes" do
      it "returns failure when person is missing" do
        params = { membership_type_id: membership_type.id, payment_method: "cash", recorded_by_id: admin_user.id }
        creator = described_class.new(params)
        
        result = creator.call
        expect(result.success?).to be false
        expect(result.message).to include("Invalid data")
      end

      it "returns failure when membership_type_id is missing" do
        params = { person: person, payment_method: "cash", recorded_by_id: admin_user.id }
        creator = described_class.new(params)
        
        result = creator.call
        expect(result.success?).to be false
      end

      it "returns failure when recorded_by_id is missing" do
        params = { person: person, membership_type_id: membership_type.id, payment_method: "cash" }
        creator = described_class.new(params)
        
        result = creator.call
        expect(result.success?).to be false
      end
    end

    context "with record not found" do
      it "returns failure when membership_type doesn't exist" do
        params = { person: person, membership_type_id: 99999, payment_method: "cash", recorded_by_id: admin_user.id }
        creator = described_class.new(params)
        
        result = creator.call
        expect(result.success?).to be false
        expect(result.message).to include("Record not found")
      end

      it "returns failure when user doesn't exist" do
        params = { person: person, membership_type_id: membership_type.id, payment_method: "cash", recorded_by_id: 99999 }
        creator = described_class.new(params)
        
        result = creator.call
        expect(result.success?).to be false
        expect(result.message).to include("Record not found")
      end
    end

    context "instrumentation" do
      let(:params) do
        {
          person: person,
          membership_type_id: membership_type.id,
          payment_method: "cash",
          recorded_by_id: admin_user.id
        }
      end

      it "fires membership.created notification" do
        expect {
          creator = described_class.new(params)
          creator.call
        }.to instrument("membership.created")
      end
    end
  end
end

