# frozen_string_literal: true

require 'rails_helper'

RSpec.describe People::PaymentUpdater do
  let(:person) { create(:person) }
  let(:admin_user) { create(:user, :admin) }
  let(:volunteer_user) { create(:user, :volunteer) }
  let(:payment) { create(:payment, person: person, total_cents: 2_500, status: :pending, payment_method: :cash, notes: 'Initial') }

  describe '#call' do
    context 'with valid attributes' do
      it 'updates provided attributes' do
        result = described_class.new(
          payment: payment,
          total_cents: 5_000,
          payment_method: 'card',
          status: 'success',
          notes: 'Updated',
          updated_by_id: admin_user.id
        ).call

        expect(result.success?).to be(true)
        payment.reload
        expect(payment.total_cents).to eq(5_000)
        expect(payment.payment_method).to eq('card')
        expect(payment.status).to eq('success')
        expect(payment.notes).to eq('Updated')
      end

      it 'allows partial update' do
        result = described_class.new(
          payment: payment,
          notes: 'Only change note',
          updated_by_id: admin_user.id
        ).call

        expect(result.success?).to be(true)
        expect(payment.reload.notes).to eq('Only change note')
      end

      it 'fires instrumentation' do
        updater = described_class.new(
          payment: payment,
          total_cents: 3_000,
          updated_by_id: admin_user.id
        )

        expect { updater.call }.to instrument('payment.updated')
      end
    end

    context 'with invalid data' do
      it 'fails when payment missing' do
        result = described_class.new(
          payment_id: nil,
          updated_by_id: admin_user.id
        ).call

        expect(result.success?).to be(false)
        expect(result.message).to include('Invalid payment data')
      end

      it 'fails when updated_by missing' do
        result = described_class.new(payment: payment).call

        expect(result.success?).to be(false)
      end

      it 'fails for invalid total' do
        result = described_class.new(
          payment: payment,
          total_cents: -100,
          updated_by_id: admin_user.id
        ).call

        expect(result.success?).to be(false)
        expect(result.message).to include('Invalid payment data')
      end
    end

    context 'with permissions' do
      it 'rejects volunteer' do
        result = described_class.new(
          payment: payment,
          notes: 'Attempt',
          updated_by_id: volunteer_user.id
        ).call

        expect(result.success?).to be(false)
        expect(result.message).to include('Insufficient permissions')
      end
    end

    context 'with missing records' do
      it 'fails when payment not found' do
        result = described_class.new(
          payment_id: 999_999,
          updated_by_id: admin_user.id
        ).call

        expect(result.success?).to be(false)
        expect(result.message).to include('Record not found')
      end

      it 'fails when updater not found' do
        result = described_class.new(
          payment: payment,
          updated_by_id: 999_999
        ).call

        expect(result.success?).to be(false)
        expect(result.message).to include('Record not found')
      end
    end
  end
end
