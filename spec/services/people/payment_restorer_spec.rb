# frozen_string_literal: true

require 'rails_helper'

RSpec.describe People::PaymentRestorer do
  let(:person) { create(:person) }
  let(:admin_user) { create(:user, :admin) }
  let(:volunteer_user) { create(:user, :volunteer) }
  let(:cancelled_payment) { create(:payment, person: person, status: :cancel, notes: 'Initial') }

  describe '#call' do
    context 'with valid attributes' do
      let(:params) do
        {
          payment: cancelled_payment,
          restored_by_id: admin_user.id,
          reason: 'Customer returned'
        }
      end

      it 'restores payment to success' do
        result = described_class.new(params).call

        expect(result.success?).to be(true)
        expect(cancelled_payment.reload.status).to eq('success')
      end

      it 'appends reason to notes' do
        described_class.new(params).call

        expect(cancelled_payment.reload.notes).to include('Restored: Customer returned')
      end

      it 'fires instrumentation' do
        restorer = described_class.new(params)

        expect { restorer.call }.to instrument('payment.restored')
      end
    end

    context 'with invalid data' do
      it 'fails when payment missing' do
        result = described_class.new(restored_by_id: admin_user.id, reason: 'Test').call

        expect(result.success?).to be(false)
        expect(result.message).to include('Invalid restoration data')
      end

      it 'fails when restored_by missing' do
        result = described_class.new(payment: cancelled_payment, reason: 'Test').call

        expect(result.success?).to be(false)
      end

      it 'fails when reason missing' do
        result = described_class.new(payment: cancelled_payment, restored_by_id: admin_user.id).call

        expect(result.success?).to be(false)
      end
    end

    context 'permissions' do
      it 'rejects volunteer' do
        result = described_class.new(
          payment: cancelled_payment,
          restored_by_id: volunteer_user.id,
          reason: 'Test'
        ).call

        expect(result.success?).to be(false)
        expect(result.message).to include('Insufficient permissions')
      end
    end

    context 'payment status' do
      it 'fails if payment not cancelled' do
        payment = create(:payment, person: person, status: :success)
        result = described_class.new(
          payment: payment,
          restored_by_id: admin_user.id,
          reason: 'Test'
        ).call

        expect(result.success?).to be(false)
        expect(result.message).to include('cannot be restored')
      end
    end

    context 'missing records' do
      it 'fails when payment not found' do
        result = described_class.new(
          payment_id: 999_999,
          restored_by_id: admin_user.id,
          reason: 'Test'
        ).call

        expect(result.success?).to be(false)
        expect(result.message).to include('Record not found')
      end

      it 'fails when user not found' do
        result = described_class.new(
          payment: cancelled_payment,
          restored_by_id: 999_999,
          reason: 'Test'
        ).call

        expect(result.success?).to be(false)
        expect(result.message).to include('Record not found')
      end
    end
  end
end
