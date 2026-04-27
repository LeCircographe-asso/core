require "rails_helper"

RSpec.describe People::PaymentCreator do
  let(:person) { create(:person) }
  let(:admin_user) { create(:user, :admin) }
  let(:membership_type) { create(:membership_type) }
  let(:membership) { create(:membership, person: person, membership_type: membership_type) }
  let(:contribution_formula) { create(:contribution_formula, :pack10) }

  describe "#call" do
    context "with valid single-line attributes" do
      subject(:result) do
        described_class.new(
          person: person,
          amount_cents: 5_000,
          payment_method: "cash",
          recorded_by_id: admin_user.id,
          item_type: "Membership",
          item_id: membership.id,
          description: "Test payment"
        ).call
      end

      it "returns success" do
        expect(result.success?).to be(true)
        expect(result.payment.total_cents).to eq(5_000)
        expect(result.payment.payment_lines.count).to eq(1)
      end

      it "associates the payment to the person and recorder" do
        payment = result.payment
        expect(payment.person).to eq(person)
        expect(payment.recorded_by).to eq(admin_user)
      end
    end

    context "with donation" do
      it "creates a payment line linked to the payment" do
        result = described_class.new(
          person: person,
          amount_cents: 10_000,
          payment_method: "cash",
          recorded_by_id: admin_user.id,
          item_type: "Donation",
          description: "Test donation"
        ).call

        expect(result.success?).to be(true)
        line = result.payment.payment_lines.first
        expect(line.item_type).to eq("Donation")
        expect(line.item_id).to eq(result.payment.id)
        expect(line.description).to eq("Test donation")
      end
    end

    context "with multiple payment lines" do
      let(:payment_lines) do
        [
          { item_type: "Membership", item_id: membership.id, amount_cents: 3_000, description: "Adhésion" },
          { item_type: "SubscriptionPlan", item_id: contribution_formula.id, amount_cents: 5_000, description: "Pack 10" }
        ]
      end

      it "creates payment with matching total" do
        result = described_class.new(
          person: person,
          payment_lines: payment_lines,
          total_cents: 8_000,
          payment_method: "cash",
          recorded_by_id: admin_user.id,
          notes: "Multiple items"
        ).call

        expect(result.success?).to be(true)
        expect(result.payment.total_cents).to eq(8_000)
        expect(result.payment.payment_lines.count).to eq(2)
      end

      it "fires instrumentation" do
        creator = described_class.new(
          person: person,
          payment_lines: payment_lines,
          total_cents: 8_000,
          payment_method: "cash",
          recorded_by_id: admin_user.id
        )

        expect { creator.call }.to instrument("payment.created")
      end
    end

    context "with invalid data" do
      it "fails when person is missing" do
        result = described_class.new(
          amount_cents: 5_000,
          payment_method: "cash",
          recorded_by_id: admin_user.id,
          item_type: "Membership",
          item_id: membership.id
        ).call

        expect(result.success?).to be(false)
        expect(result.message).to include("Invalid payment data")
      end

      it "fails when payment_method is invalid" do
        result = described_class.new(
          person: person,
          amount_cents: 5_000,
          payment_method: "crypto",
          recorded_by_id: admin_user.id,
          item_type: "Membership",
          item_id: membership.id
        ).call

        expect(result.success?).to be(false)
        expect(result.message).to include("Invalid payment data")
      end

      it "fails when payment lines total mismatch" do
        result = described_class.new(
          person: person,
          payment_lines: [ { item_type: "Membership", item_id: membership.id, amount_cents: 1_000 } ],
          total_cents: 2_000,
          payment_method: "cash",
          recorded_by_id: admin_user.id
        ).call

        expect(result.success?).to be(false)
        expect(result.message).to include("La somme des lignes")
      end
    end
  end
end
