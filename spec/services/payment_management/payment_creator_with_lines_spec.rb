require 'rails_helper'

RSpec.describe PaymentManagement::PaymentCreatorWithLines do
  let(:person) { create(:person) }
  let(:admin_user) { create(:user, :admin) }
  let(:membership_type) { create(:membership_type) }
  let(:membership) { create(:membership, person: person, membership_type: membership_type) }
  let(:subscription_plan) { create(:subscription_plan, :pack10) }

  describe "#call" do
    context "with valid attributes" do
      let(:params) do
        {
          person_id: person.id,
          total_cents: 8000,
          payment_method: "cash",
          recorded_by_id: admin_user.id,
          notes: "Multiple items",
          payment_lines: [
            { item_type: "Membership", item_id: membership.id, amount_cents: 3000, description: "Adhésion" },
            { item_type: "SubscriptionPlan", item_id: subscription_plan.id, amount_cents: 5000, description: "Pack 10" }
          ]
        }
      end

      it "creates payment with matching lines" do
        creator = described_class.new(params)
        result = creator.call

        expect(result.success?).to be true
        expect(result.payment.total_cents).to eq(8000)
        expect(result.payment.payment_lines.count).to eq(2)
      end

      it "fires instrumentation" do
        creator = described_class.new(params)

        expect { creator.call }.to instrument("payment.created")
      end
    end

    context "with invalid attributes" do
      it "fails when total and lines mismatch" do
        params = {
          person_id: person.id,
          total_cents: 8000,
          payment_method: "cash",
          recorded_by_id: admin_user.id,
          payment_lines: [
            { item_type: "Membership", item_id: membership.id, amount_cents: 3000 },
            { item_type: "SubscriptionPlan", item_id: subscription_plan.id, amount_cents: 4000 }
          ]
        }

        creator = described_class.new(params)
        result = creator.call

        expect(result.success?).to be false
        expect(result.message).to include("La somme des lignes")
      end

      it "fails when person not found" do
        params = {
          person_id: 999_999,
          total_cents: 1000,
          payment_method: "cash",
          recorded_by_id: admin_user.id,
          payment_lines: [ { item_type: "Membership", item_id: membership.id, amount_cents: 1000 } ]
        }

        creator = described_class.new(params)
        result = creator.call

        expect(result.success?).to be false
        expect(result.message).to include("Person or User not found")
      end

      it "fails when recorded_by user not found" do
        params = {
          person_id: person.id,
          total_cents: 1000,
          payment_method: "cash",
          recorded_by_id: 999_999,
          payment_lines: [ { item_type: "Membership", item_id: membership.id, amount_cents: 1000 } ]
        }

        creator = described_class.new(params)
        result = creator.call

        expect(result.success?).to be false
        expect(result.message).to include("Person or User not found")
      end
    end
  end
end
