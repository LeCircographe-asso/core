require 'rails_helper'

RSpec.describe PaymentManagement::PaymentDeleter do
  let(:person) { create(:person) }
  let(:admin_user) { create(:user, system_role: :admin) }
  let(:volunteer_user) { create(:user, system_role: :volunteer) }
  let(:payment) { create(:payment, person: person, status: :success) }

  describe "#call" do
    context "with valid attributes" do
      let(:params) do
        {
          payment_id: payment.id,
          deleted_by_id: admin_user.id,
          reason: "Mistake"
        }
      end

      it "marks payment as cancelled" do
        deleter = described_class.new(params)
        result = deleter.call

        expect(result.success?).to be true
        expect(payment.reload.status).to eq("cancel")
      end

      it "adds cancellation reason to notes" do
        deleter = described_class.new(params)
        deleter.call

        expect(payment.reload.notes).to include("Cancelled: Mistake")
      end
    end

    context "with invalid attributes" do
      it "returns failure when payment_id is missing" do
        params = { deleted_by_id: admin_user.id, reason: "Test" }
        deleter = described_class.new(params)
        
        result = deleter.call
        expect(result.success?).to be false
      end

      it "returns failure when deleted_by_id is missing" do
        params = { payment_id: payment.id, reason: "Test" }
        deleter = described_class.new(params)
        
        result = deleter.call
        expect(result.success?).to be false
      end

      it "returns failure when reason is missing" do
        params = { payment_id: payment.id, deleted_by_id: admin_user.id }
        deleter = described_class.new(params)
        
        result = deleter.call
        expect(result.success?).to be false
      end
    end

    context "with permission checks" do
      it "allows admin to delete payment" do
        params = { payment_id: payment.id, deleted_by_id: admin_user.id, reason: "Test" }
        deleter = described_class.new(params)
        
        result = deleter.call
        expect(result.success?).to be true
      end

      it "rejects volunteer deletion" do
        params = { payment_id: payment.id, deleted_by_id: volunteer_user.id, reason: "Test" }
        deleter = described_class.new(params)
        
        result = deleter.call
        expect(result.success?).to be false
        expect(result.message).to include("Insufficient permissions")
      end
    end

    context "with already cancelled payment" do
      it "returns failure when payment is already cancelled" do
        cancelled_payment = create(:payment, person: person, status: :cancel)
        params = { payment_id: cancelled_payment.id, deleted_by_id: admin_user.id, reason: "Test" }
        deleter = described_class.new(params)
        
        result = deleter.call
        expect(result.success?).to be false
        expect(result.message).to include("already cancelled")
      end
    end

    context "with record not found" do
      it "returns failure when payment doesn't exist" do
        params = { payment_id: 99999, deleted_by_id: admin_user.id, reason: "Test" }
        deleter = described_class.new(params)
        
        result = deleter.call
        expect(result.success?).to be false
      end
    end

    context "instrumentation" do
      let(:params) do
        {
          payment_id: payment.id,
          deleted_by_id: admin_user.id,
          reason: "Test"
        }
      end

      it "fires payment.cancelled notification" do
        expect {
          deleter = described_class.new(params)
          deleter.call
        }.to instrument("payment.cancelled")
      end
    end
  end
end

