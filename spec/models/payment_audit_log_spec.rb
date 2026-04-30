require 'rails_helper'

RSpec.describe PaymentAuditLog, type: :model do
  let(:payment) { create(:payment) }
  let(:user) { create(:user, :admin) }

  describe 'associations' do
    it { should belong_to(:payment) }
    it { should belong_to(:user).optional }
  end

  describe 'validations' do
    it { should validate_presence_of(:action) }
  end

  describe '.log' do
    it 'creates a log entry with payment, user, and action' do
      log = PaymentAuditLog.log(payment, user, 'create')
      expect(log.payment).to eq(payment)
      expect(log.user).to eq(user)
      expect(log.action).to eq('create')
    end

    it 'accepts optional change_data hash' do
      change_data = { old_status: 'pending', new_status: 'success' }
      log = PaymentAuditLog.log(payment, user, 'update', change_data)
      expect(log.change_data).to eq(change_data.to_json)
    end

    it 'can create log without user' do
      log = PaymentAuditLog.log(payment, nil, 'system_update')
      expect(log.user).to be_nil
      expect(log.action).to eq('system_update')
    end

    it 'saves change_data as JSON string' do
      change_data = { amount: 5000, notes: 'Updated' }
      log = PaymentAuditLog.log(payment, user, 'update', change_data)
      parsed = JSON.parse(log.change_data)
      expect(parsed['amount']).to eq(5000)
    end
  end
end
