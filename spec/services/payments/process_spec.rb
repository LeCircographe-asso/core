require 'rails_helper'

RSpec.describe Payments::Process, type: :service do
  let(:person) { create(:person) }
  let(:user) { create(:user) }
  let(:membership_type) { create(:membership_type) }
  let(:subscription_plan) { create(:subscription_plan, duration: :pack10, sessions_count: 10) }

  describe '#call' do
    context 'with valid payment' do
      let(:payment) { create(:payment, person: person, recorded_by: user, status: :pending) }

      it 'processes payment successfully' do
        service = described_class.new(payment)
        result = service.call

        expect(result.success?).to be true
        expect(payment.reload.status).to eq('success')
      end
    end

    context 'with membership type payment line' do
      let(:payment) { create(:payment, person: person, recorded_by: user, status: :pending) }
      let!(:payment_line) { create(:payment_line, 
        payment: payment, 
        item: membership_type, 
        amount_cents: membership_type.price_cents
      ) }

      it 'creates membership when processing payment' do
        service = described_class.new(payment)
        result = service.call

        expect(result.success?).to be true
        expect(person.memberships.count).to eq(1)
        
        membership = person.memberships.first
        expect(membership.membership_type).to eq(membership_type)
        expect(membership.status).to eq('active')
      end
    end

    context 'with subscription plan payment line (pack)' do
      let(:payment) { create(:payment, person: person, recorded_by: user, status: :pending) }
      let!(:payment_line) { create(:payment_line, 
        payment: payment, 
        item: subscription_plan, 
        amount_cents: subscription_plan.price_cents
      ) }

      it 'creates book of entry for pack subscription plan' do
        service = described_class.new(payment)
        result = service.call

        expect(result.success?).to be true
        expect(person.book_of_entries.count).to eq(1)
        
        book_of_entry = person.book_of_entries.first
        expect(book_of_entry.subscription_plan).to eq(subscription_plan)
        expect(book_of_entry.sessions_remaining).to eq(subscription_plan.sessions_count)
        expect(book_of_entry.status).to eq('active')
      end
    end

    context 'with non-pack subscription plan payment line' do
      let(:day_plan) { create(:subscription_plan, duration: :day) }
      let(:payment) { create(:payment, person: person, recorded_by: user, status: :pending) }
      let!(:payment_line) { create(:payment_line, 
        payment: payment, 
        item: day_plan, 
        amount_cents: day_plan.price_cents
      ) }

      it 'does not create book of entry for non-pack plans' do
        service = described_class.new(payment)
        result = service.call

        expect(result.success?).to be true
        expect(person.book_of_entries.count).to eq(0)
      end
    end

    context 'when payment is already processed' do
      let(:payment) { create(:payment, person: person, recorded_by: user, status: :success) }

      it 'fails with appropriate message' do
        service = described_class.new(payment)
        result = service.call

        expect(result.success?).to be false
        expect(result.message).to eq('Payment is already processed')
      end
    end

    context 'when payment is nil' do
      it 'fails with appropriate message' do
        service = described_class.new(nil)
        result = service.call

        expect(result.success?).to be false
        expect(result.message).to eq('Payment is required')
      end
    end

    context 'with multiple payment lines' do
      let(:payment) { create(:payment, person: person, recorded_by: user, status: :pending) }
      let!(:membership_line) { create(:payment_line, 
        payment: payment, 
        item: membership_type, 
        amount_cents: membership_type.price_cents
      ) }
      let!(:subscription_line) { create(:payment_line, 
        payment: payment, 
        item: subscription_plan, 
        amount_cents: subscription_plan.price_cents
      ) }

      it 'processes all payment lines' do
        service = described_class.new(payment)
        result = service.call

        expect(result.success?).to be true
        expect(person.memberships.count).to eq(1)
        expect(person.book_of_entries.count).to eq(1)
      end
    end
  end
end
