require 'rails_helper'

RSpec.describe PaymentManagement::PaymentRestorer do
  let(:person) { create(:person) }
  let(:admin_user) { create(:user, :admin) }
  let(:volunteer_user) { create(:user, :volunteer) }
  let(:cancelled_payment) { create(:payment, person: person, status: :cancel, notes: "Initial note") }

  describe "#call" do
    context "with valid attributes" do
      let(:params) do
        {
          payment_id: cancelled_payment.id,
          restored_by_id: admin_user.id,
          reason: "Customer returned"
        }
      end

      it "restores the payment to success" do
        restorer = described_class.new(params)
        result = restorer.call

        expect(result.success?).to be true
        expect(cancelled_payment.reload.status).to eq("success")
      end

      it "appends restoration reason to notes" do
        restorer = described_class.new(params)
        restorer.call

        expect(cancelled_payment.reload.notes).to include("Restored: Customer returned")
      end

      it "fires instrumentation" do
        restorer = described_class.new(params)

        expect { restorer.call }.to instrument("payment.restored")
      end
    end

    context "with invalid attributes" do
      it "fails when payment_id missing" do
        restorer = described_class.new(restored_by_id: admin_user.id, reason: "Test")

        result = restorer.call
        expect(result.success?).to be false
        expect(result.message).to include("Invalid restoration data")
      end

      it "fails when restored_by_id missing" do
        restorer = described_class.new(payment_id: cancelled_payment.id, reason: "Test")

        result = restorer.call
        expect(result.success?).to be false
      end

      it "fails when reason missing" do
        restorer = described_class.new(payment_id: cancelled_payment.id, restored_by_id: admin_user.id)

        result = restorer.call
        expect(result.success?).to be false
      end
    end

    context "with permission checks" do
      it "rejects volunteer" do
        restorer = described_class.new(
          payment_id: cancelled_payment.id,
          restored_by_id: volunteer_user.id,
          reason: "Test"
        )

        result = restorer.call
        expect(result.success?).to be false
        expect(result.message).to include("Insufficient permissions")
      end
    end

    context "with payment status" do
      it "fails if payment not cancelled" do
        payment = create(:payment, person: person, status: :success)
        restorer = described_class.new(
          payment_id: payment.id,
          restored_by_id: admin_user.id,
          reason: "Test"
        )

        result = restorer.call
        expect(result.success?).to be false
        expect(result.message).to include("cannot be restored")
      end
    end

    context "with missing records" do
      it "fails when payment not found" do
        restorer = described_class.new(
          payment_id: 999_999,
          restored_by_id: admin_user.id,
          reason: "Test"
        )

        result = restorer.call
        expect(result.success?).to be false
        expect(result.message).to include("Payment or User not found")
      end

      it "fails when user not found" do
        restorer = described_class.new(
          payment_id: cancelled_payment.id,
          restored_by_id: 999_999,
          reason: "Test"
        )

        result = restorer.call
        expect(result.success?).to be false
        expect(result.message).to include("Payment or User not found")
      end
    end
  end
end


