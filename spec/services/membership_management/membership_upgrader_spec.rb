require 'rails_helper'

RSpec.describe MembershipManagement::MembershipUpgrader do
  let(:person) { create(:person) }
  let(:basic_type) { create(:membership_type, category: :basic, price_cents: 100) }
  let(:circus_type) { create(:membership_type, category: :circus, price_cents: 1000) }
  let(:admin_user) { create(:user, system_role: :admin) }

  before do
    # Create initial membership for upgrade tests
    person.create_membership!(basic_type, payment_method: :cash, recorded_by: admin_user)
  end

  describe "#call" do
    context "with valid attributes" do
      let(:params) do
        {
          person: person,
          new_membership_type_id: circus_type.id,
          payment_method: "cash",
          recorded_by_id: admin_user.id
        }
      end

      it "upgrades membership successfully" do
        upgrader = described_class.new(params)
        result = upgrader.call

        expect(result.success?).to be true
        expect(result.membership).to be_present
        expect(result.payment).to be_present
      end

      it "charges full price of new membership type" do
        upgrader = described_class.new(params)
        result = upgrader.call

        expect(result.payment.total_cents).to eq(circus_type.price_cents)
      end

      it "creates new membership with circus type" do
        upgrader = described_class.new(params)
        result = upgrader.call

        expect(result.membership.membership_type).to eq(circus_type)
      end

      it "marks old membership as inactive" do
        old_membership = person.current_membership
        upgrader = described_class.new(params)
        upgrader.call

        expect(old_membership.reload.status).to eq("inactive")
      end
    end


    context "with member number change" do
      let(:params) do
        {
          person: person,
          new_membership_type_id: circus_type.id,
          payment_method: "cash",
          recorded_by_id: admin_user.id
        }
      end

      it "returns member number change info" do
        upgrader = described_class.new(params)
        result = upgrader.call

        expect(result.member_number_changed).to be_in([true, false])
        expect(result.old_member_number).to be_present
        expect(result.new_member_number).to be_present
      end
    end

    context "with invalid attributes" do
      it "returns failure when person is missing" do
        params = { new_membership_type_id: circus_type.id, payment_method: "cash", recorded_by_id: admin_user.id }
        upgrader = described_class.new(params)
        
        result = upgrader.call
        expect(result.success?).to be false
      end

      it "returns failure when new_membership_type_id is missing" do
        params = { person: person, payment_method: "cash", recorded_by_id: admin_user.id }
        upgrader = described_class.new(params)
        
        result = upgrader.call
        expect(result.success?).to be false
      end
    end

    context "with record not found" do
      it "returns failure when membership_type doesn't exist" do
        params = { person: person, new_membership_type_id: 99999, payment_method: "cash", recorded_by_id: admin_user.id }
        upgrader = described_class.new(params)
        
        result = upgrader.call
        expect(result.success?).to be false
        expect(result.message).to include("Record not found")
      end
    end

    context "instrumentation" do
      let(:params) do
        {
          person: person,
          new_membership_type_id: circus_type.id,
          payment_method: "cash",
          recorded_by_id: admin_user.id
        }
      end

      it "fires membership.upgraded notification" do
        expect {
          upgrader = described_class.new(params)
          upgrader.call
        }.to instrument("membership.upgraded")
      end
    end
  end
end

