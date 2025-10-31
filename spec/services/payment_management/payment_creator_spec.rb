require 'rails_helper'

RSpec.describe PaymentManagement::PaymentCreator do
  let(:person) { create(:person) }
  let(:admin_user) { create(:user, :admin) }
  let(:membership_type) { create(:membership_type) }
  let(:membership) { create(:membership, person: person, membership_type: membership_type) }

  describe "#call" do
    context "with valid attributes" do
      let(:valid_attributes) do
        {
          person_id: person.id,
          amount_cents: 5000,
          payment_method: "cash",
          recorded_by_id: admin_user.id,
          item_type: "Membership",
          item_id: membership.id,
          description: "Test payment"
        }
      end

      it "creates a payment successfully" do
        creator = described_class.new(valid_attributes)
        result = creator.call

        expect(result.success?).to be true
        expect(result.payment).to be_present
        expect(result.payment.total_cents).to eq(5000)
      end


      it "creates a payment line" do
        creator = described_class.new(valid_attributes)
        result = creator.call

        expect(result.payment.payment_lines.count).to eq(1)
        expect(result.payment.payment_lines.first.item_type).to eq("Membership")
        expect(result.payment.payment_lines.first.amount_cents).to eq(5000)
      end

      it "associates payment with person and user" do
        creator = described_class.new(valid_attributes)
        result = creator.call

        expect(result.payment.person).to eq(person)
        expect(result.payment.recorded_by).to eq(admin_user)
      end

      context "with donation" do
      let(:donation_attributes) do
        {
          person_id: person.id,
          amount_cents: 10000,
          payment_method: "cash",
          recorded_by_id: admin_user.id,
          item_type: "Donation",
          item_id: 1,
          description: "Test donation"
        }
      end

        it "creates donation payment line correctly" do
          creator = described_class.new(donation_attributes)
          result = creator.call

          line = result.payment.payment_lines.first
          expect(line.item_type).to eq("Payment")
          expect(line.item_id).to eq(result.payment.id)
          expect(line.description).to eq("Test donation")
        end
      end
    end

    context "with invalid attributes" do
      it "returns failure when person_id is missing" do
        creator = described_class.new(
          amount_cents: 5000,
          payment_method: "cash",
          recorded_by_id: admin_user.id,
          item_type: "Membership",
          item_id: 1
        )
        result = creator.call

        expect(result.success?).to be false
        expect(result.message).to include("Invalid payment data")
      end

      it "returns failure when amount_cents is invalid" do
        creator = described_class.new(
          person_id: person.id,
          amount_cents: -100,
          payment_method: "cash",
          recorded_by_id: admin_user.id,
          item_type: "Membership",
          item_id: 1
        )
        result = creator.call

        expect(result.success?).to be false
      end

      it "returns failure when payment_method is invalid" do
        creator = described_class.new(
          person_id: person.id,
          amount_cents: 5000,
          payment_method: "invalid",
          recorded_by_id: admin_user.id,
          item_type: "Membership",
          item_id: 1
        )
        result = creator.call

        expect(result.success?).to be false
      end

      it "handles non-existent person" do
        creator = described_class.new(
          person_id: 9999,
          amount_cents: 5000,
          payment_method: "cash",
          recorded_by_id: admin_user.id,
          item_type: "Membership",
          item_id: 1
        )
        result = creator.call

        expect(result.success?).to be false
        expect(result.message).to include("Person or User not found")
      end

      it "handles non-existent recorded_by user" do
        creator = described_class.new(
          person_id: person.id,
          amount_cents: 5000,
          payment_method: "cash",
          recorded_by_id: 9999,
          item_type: "Membership",
          item_id: 1
        )
        result = creator.call

        expect(result.success?).to be false
        expect(result.message).to include("Person or User not found")
      end
    end

    context "different payment methods" do
      %w[cash card cheque transfer].each do |method|
        it "accepts #{method} as valid payment method" do
          creator = described_class.new(
            person_id: person.id,
            amount_cents: 5000,
            payment_method: method,
            recorded_by_id: admin_user.id,
            item_type: "Membership",
            item_id: membership.id
          )
          result = creator.call

          expect(result.success?).to be true
          expect(result.payment.payment_method).to eq(method)
        end
      end
    end
  end
end

