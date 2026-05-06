# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::Donations', type: :request do
  let(:admin) { create(:user, :admin) }

  before { login_as(admin) }

  describe 'GET /admin/donations/new' do
    let(:person) { create(:person, first_name: 'Ada', last_name: 'Lovelace') }

    it 'returns success when person_id is given' do
      get new_admin_donation_path(person_id: person.id)
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Ada')
      expect(response.body).to include(admin_member_path(person))
    end

    it 'redirects when person context is missing' do
      get new_admin_donation_path
      expect(response).to redirect_to(admin_members_path)
    end

    it 'legacy GET /admin/donations redirects to new preserving query string' do
      get "/admin/donations", params: { person_id: person.id }
      expect(response).to redirect_to(new_admin_donation_path(person_id: person.id))
    end
  end

  describe 'POST /admin/donations' do
    let(:person) { create(:person) }

    it 'creates a donation payment with person_id' do
      expect do
        post admin_donations_path, params: {
          person_id: person.id,
          payment: {
            payment_amount: 12.50
          }
        }
      end.to change(Payment, :count).by(1)

      payment = Payment.order(:created_at).last
      expect(payment.person).to eq(person)
      expect(payment.recorded_by).to eq(admin)
      expect(payment.total_cents).to eq(1250)

      line = payment.payment_lines.sole
      expect(line.item_type).to eq('Donation')
      expect(line.item_id).to eq(payment.id)
      expect(line.amount_cents).to eq(1250)
      expect(line.description).to eq('Donation')
      expect(response).to redirect_to(admin_payments_path(person_id: person.id))
    end

    it 'creates a donation payment with legacy user_id' do
      user = create(:user, :admin, person: person)

      expect do
        post admin_donations_path, params: {
          user_id: user.id,
          payment: {
            payment_amount: 5
          }
        }
      end.to change(Payment, :count).by(1)

      payment = Payment.order(:created_at).last
      expect(payment.person).to eq(person)
      expect(payment.recorded_by).to eq(admin)
      expect(payment.total_cents).to eq(500)

      line = payment.payment_lines.sole
      expect(line.item_type).to eq('Donation')
      expect(line.item_id).to eq(payment.id)
      expect(line.amount_cents).to eq(500)
      expect(response).to redirect_to(admin_payments_path(person_id: person.id))
    end
  end
end
