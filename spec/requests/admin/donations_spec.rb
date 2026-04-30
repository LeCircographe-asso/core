require 'rails_helper'

RSpec.describe 'Admin::Donations', type: :request do
  let(:admin) { create(:user, :admin) }

  before { login_as(admin) }

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
    end
  end
end
