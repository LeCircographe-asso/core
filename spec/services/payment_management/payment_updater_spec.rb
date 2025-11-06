require 'rails_helper'

RSpec.describe PaymentManagement::PaymentUpdater do
  let(:person) { create(:person) }
  let(:admin_user) { create(:user, :admin) }
  let(:volunteer_user) { create(:user, :volunteer) }
  let(:payment) { create(:payment, person: person, total_cents: 2500, status: :pending, payment_method: :cash, notes: "Initial") }

  describe "#call" do
    context "with valid attributes" do
      it "updates provided attributes only" do
        updater = described_class.new(
          payment_id: payment.id,
          total_cents: 5000,
          payment_method: "card",
          status: "success",
          notes: "Updated",
          updated_by_id: admin_user.id
        )

        result = updater.call

        expect(result.success?).to be true
        payment.reload
        expect(payment.total_cents).to eq(5000)
        expect(payment.payment_method).to eq("card")
        expect(payment.status).to eq("success")
        expect(payment.notes).to eq("Updated")
      end

      it "allows partial updates" do
        updater = described_class.new(
          payment_id: payment.id,
          notes: "Only note change",
          updated_by_id: admin_user.id
        )

        result = updater.call

        expect(result.success?).to be true
        expect(payment.reload.notes).to eq("Only note change")
      end

      it "fires instrumentation" do
        updater = described_class.new(
          payment_id: payment.id,
          total_cents: 3000,
          updated_by_id: admin_user.id
        )

        expect { updater.call }.to instrument("payment.updated")
      end
    end

    context "with invalid attributes" do
      it "fails when payment_id missing" do
        updater = described_class.new(
          total_cents: 5000,
          updated_by_id: admin_user.id
        )

        result = updater.call

        expect(result.success?).to be false
        expect(result.message).to include("Invalid payment data")
      end

      it "fails when updated_by_id missing" do
        updater = described_class.new(payment_id: payment.id)

        result = updater.call

        expect(result.success?).to be false
      end

      it "fails for invalid total_cents" do
        updater = described_class.new(
          payment_id: payment.id,
          total_cents: -100,
          updated_by_id: admin_user.id
        )

        result = updater.call

        expect(result.success?).to be false
        expect(result.message).to include("Invalid payment data")
      end

      it "fails for invalid payment_method" do
        updater = described_class.new(
          payment_id: payment.id,
          payment_method: "crypto",
          updated_by_id: admin_user.id
        )

        result = updater.call

        expect(result.success?).to be false
      end
    end

    context "with permission checks" do
      it "rejects volunteer" do
        updater = described_class.new(
          payment_id: payment.id,
          notes: "Attempted",
          updated_by_id: volunteer_user.id
        )

        result = updater.call

        expect(result.success?).to be false
        expect(result.message).to include("Insufficient permissions")
      end
    end

    context "with missing records" do
      it "fails when payment not found" do
        updater = described_class.new(
          payment_id: 999_999,
          updated_by_id: admin_user.id
        )

        result = updater.call

        expect(result.success?).to be false
        expect(result.message).to include("Payment or User not found")
      end

      it "fails when user not found" do
        updater = described_class.new(
          payment_id: payment.id,
          updated_by_id: 999_999
        )

        result = updater.call

        expect(result.success?).to be false
        expect(result.message).to include("Payment or User not found")
      end
    end
  end
end


