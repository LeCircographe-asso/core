require 'rails_helper'

RSpec.describe People::PaymentCanceller do
  let(:person) { create(:person) }
  let(:admin_user) { create(:user, :admin) }
  let(:volunteer_user) { create(:user, :volunteer) }
  let(:payment) { create(:payment, person: person, status: :success, notes: 'Initial note') }

  describe '#call' do
    context 'with valid attributes' do
      let(:params) do
        {
          payment: payment,
          deleted_by_id: admin_user.id,
          reason: 'Mistake'
        }
      end

      it 'marks payment as cancelled' do
        result = described_class.new(params).call

        expect(result.success?).to be(true)
        expect(payment.reload.status).to eq('cancel')
      end

      it 'appends reason to notes' do
        described_class.new(params).call

        expect(payment.reload.notes).to include('Cancelled: Mistake')
      end

      it 'fires instrumentation' do
        canceller = described_class.new(params)

        expect { canceller.call }.to instrument('payment.cancelled')
      end
    end

    context 'with invalid data' do
      it 'fails when payment missing' do
        result = described_class.new(deleted_by_id: admin_user.id, reason: 'Test').call

        expect(result.success?).to be(false)
        expect(result.message).to include('Invalid deletion data')
      end

      it 'fails when deleted_by missing' do
        result = described_class.new(payment: payment, reason: 'Test').call

        expect(result.success?).to be(false)
      end

      it 'fails when reason missing' do
        result = described_class.new(payment: payment, deleted_by_id: admin_user.id).call

        expect(result.success?).to be(false)
      end
    end

    context 'permissions' do
      it 'rejects volunteer' do
        result = described_class.new(
          payment: payment,
          deleted_by_id: volunteer_user.id,
          reason: 'Test'
        ).call

        expect(result.success?).to be(false)
        expect(result.message).to include('Insufficient permissions')
      end
    end

    context 'with already cancelled payment' do
      it 'fails when payment already cancelled' do
        cancelled_payment = create(:payment, person: person, status: :cancel)
        result = described_class.new(
          payment: cancelled_payment,
          deleted_by_id: admin_user.id,
          reason: 'Test'
        ).call

        expect(result.success?).to be(false)
        expect(result.message).to include('already cancelled')
      end
    end

    context 'missing records' do
      it 'fails when payment not found' do
        result = described_class.new(
          payment_id: 999_999,
          deleted_by_id: admin_user.id,
          reason: 'Test'
        ).call

        expect(result.success?).to be(false)
        expect(result.message).to include('Record not found')
      end

      it 'fails when user not found' do
        result = described_class.new(
          payment: payment,
          deleted_by_id: 999_999,
          reason: 'Test'
        ).call

        expect(result.success?).to be(false)
        expect(result.message).to include('Record not found')
      end
    end
  end
end
