# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::PaymentsService do
  let(:admin_user) { create(:user, :admin) }
  let(:person_one) { create(:person, first_name: 'Alice', last_name: 'Test', email: 'alice@example.com') }
  let(:person_two) { create(:person, first_name: 'Bob', last_name: 'Sample', email: 'bob@example.com') }

  let!(:payment_success) { create(:payment, :success, person: person_one, total_cents: 2_500, recorded_by: admin_user, created_at: Time.zone.parse('2025-02-10 10:00')) }
  let!(:payment_pending) { create(:payment, :pending, person: person_two, total_cents: 1_000, recorded_by: admin_user, created_at: Time.zone.parse('2025-02-12 12:00')) }
  let!(:donation_payment) { create(:payment, :success, person: person_one, total_cents: 5_000, recorded_by: admin_user) }
  let!(:donation_line) { create(:payment_line, payment: donation_payment, item_type: 'Donation', item_id: donation_payment.id, amount_cents: 5_000, description: 'Donation') }

  describe '#call' do
    it 'returns all payments with aggregated amounts by default' do
      result = described_class.new.call

      expect(result[:payments]).to match_array([payment_success, payment_pending, donation_payment])
      expect(result[:total_amount]).to eq(7_500) # only success payments counted
      expect(result[:total_donation]).to eq(5_000)
      expect(result[:pagy].last).to match_array([payment_success, payment_pending, donation_payment])
    end

    it 'filters payments by person_id' do
      result = described_class.new(person_id: person_two.id).call

      expect(result[:payments]).to match_array([payment_pending])
    end

    it 'ignores unknown filters and returns unfiltered payments' do
      user_for_person = create(:user, :volunteer, person: person_two)
      result = described_class.new(user_id: user_for_person.id).call

      expect(result[:payments]).to match_array([payment_success, payment_pending, donation_payment])
    end

    it 'filters by status' do
      result = described_class.new(status: 'pending').call

      expect(result[:payments]).to match_array([payment_pending])
    end

    it 'filters by date range' do
      params = {
        start_date: '2025-02-09',
        end_date: '2025-02-11'
      }

      result = described_class.new(params).call

      expect(result[:payments]).to match_array([payment_success])
    end

    it 'filters by search term across person info and amount' do
      result = described_class.new(search: 'alice').call

      expect(result[:payments]).to match_array([payment_success, donation_payment])

      result_amount = described_class.new(search: '1000').call
      expect(result_amount[:payments]).to match_array([payment_pending])
    end

    it 'supports pagination order parameters' do
      result = described_class.new(sort: 'created_at', direction: 'asc', items: 2).call

      expect(result[:pagy].last.first).to eq(payment_success)
      expect(result[:pagy].last.second).to eq(payment_pending)
    end
  end
end
