# frozen_string_literal: true

require 'rails_helper'
require 'nokogiri'

RSpec.describe 'Admin::Payments', type: :request do
  describe 'GET /admin/payments' do
    context 'when not authenticated' do
      it 'redirects to login' do
        get admin_payments_path
        expect(response).to redirect_to(new_session_path)
      end
    end

    context 'when authenticated as web_visitor' do
      let(:user) { create(:user, system_role: :web_visitor) }

      before { login_as(user) }

      it 'redirects to root with alert' do
        get admin_payments_path
        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include('accès')
      end
    end

    context 'when authenticated as admin' do
      let(:admin) { create(:user, :admin) }
      let(:person) { create(:person) }

      before { login_as(admin) }

      it 'returns http success' do
        get admin_payments_path
        expect(response).to have_http_status(:success)
      end

      it 'displays list of payments' do
        create(:payment, person: person, recorded_by: admin, total_cents: 5000, payment_method: 'cash')

        get admin_payments_path
        expect(response.body).to include(person.full_name)
        expect(response.body).to include('50') # Check for amount in localized format
      end

      it 'filters by person_id' do
        person1 = create(:person, first_name: 'Alice', last_name: 'TestA')
        person2 = create(:person, first_name: 'Bob', last_name: 'TestB')
        create(:payment, person: person1, recorded_by: admin, total_cents: 5000)
        create(:payment, person: person2, recorded_by: admin, total_cents: 3000)

        get admin_payments_path, params: { person_id: person1.id }

        html = Nokogiri::HTML(response.body)
        displayed_names = html.css('tbody#payments td:nth-child(2)').map { |cell| cell.text.strip }

        expect(displayed_names).to include('Alice TestA')
        expect(displayed_names).not_to include('Bob TestB')
      end
    end
  end

  describe 'GET /admin/payments/new' do
    let(:admin) { create(:user, :admin) }

    before { login_as(admin) }

    it 'redirects to index with notice' do
      get new_admin_payment_path
      expect(response).to redirect_to(admin_payments_path)
      follow_redirect!
      expect(response.body).to include('Création de paiement temporairement désactivée')
    end

    context 'with person_id param' do
      let(:person) { create(:person) }

      it 'redirects to index with notice' do
        get new_admin_payment_path, params: { person_id: person.id }
        expect(response).to redirect_to(admin_payments_path)
        follow_redirect!
        expect(response.body).to include('Création de paiement temporairement désactivée')
      end
    end
  end

  describe 'POST /admin/payments' do
    let(:admin) { create(:user, :admin) }
    let(:person) { create(:person) }

    before { login_as(admin) }

    context 'with valid attributes' do
      it 'creates a payment' do
        expect do
          post admin_payments_path, params: {
            payment: {
              person_id: person.id,
              total_cents: 5000,
              payment_method: 'cash',
              notes: 'Test payment'
            }
          }
        end.to change { Payment.count }.by(1)
      end

      it 'sets recorded_by to current user' do
        post admin_payments_path, params: {
          payment: {
            person_id: person.id,
            total_cents: 5000,
            payment_method: 'cash'
          }
        }

        payment = Payment.last
        expect(payment.recorded_by).to eq(admin)
      end

      it 'converts euros to cents' do
        post admin_payments_path, params: {
          payment: {
            person_id: person.id,
            total_cents: 50.50, # euros
            payment_method: 'cash'
          }
        }

        payment = Payment.last
        expect(payment.total_cents).to eq(5050) # centimes
      end

      it 'redirects to payments index with success notice' do
        post admin_payments_path, params: {
          payment: {
            person_id: person.id,
            total_cents: 5000,
            payment_method: 'cash'
          }
        }

        expect(response).to redirect_to(admin_payments_path)
        follow_redirect!
        expect(response.body).to include('succès')
      end

      it 'creates a donation payment line via PaymentCreator' do
        post admin_payments_path, params: {
          payment: {
            person_id: person.id,
            total_cents: 15.00,
            payment_method: 'card',
            notes: 'Donation test'
          }
        }

        payment = Payment.order(:created_at).last
        expect(payment.total_cents).to eq(1500)
        expect(payment.payment_lines.count).to eq(1)
        line = payment.payment_lines.first
        expect(line.item_type).to eq('Donation')
        expect(line.item_id).to eq(payment.id)
        expect(line.amount_cents).to eq(1500)
        expect(line.description).to eq('Paiement direct')
      end

      it 'persists offer_reason on an offered payment' do
        post admin_payments_path, params: {
          payment: {
            person_id: person.id,
            total_cents: 0,
            payment_method: 'offered',
            offer_reason: 'Solidarity'
          }
        }

        payment = Payment.order(:created_at).last
        expect(payment.offer_reason).to eq('Solidarity')
      end
    end

    context 'with invalid attributes' do
      it 'does not create a payment without person_id' do
        expect do
          post admin_payments_path, params: {
            payment: {
              total_cents: 5000,
              payment_method: 'cash'
            }
          }
        end.not_to(change { Payment.count })
      end

      it 'redirects with error message' do
        post admin_payments_path, params: {
          payment: {
            total_cents: 5000,
            payment_method: 'cash'
          }
        }

        expect(response).to redirect_to(admin_payments_path)
        follow_redirect!
        expect(response.body).to include('Erreur')
      end
    end
  end

  describe 'PATCH /admin/payments/:id' do
    let(:admin) { create(:user, :admin) }
    let(:person) { create(:person) }
    let(:payment) { create(:payment, person: person, recorded_by: admin, total_cents: 5000, payment_method: 'cash') }

    before { login_as(admin) }

    context 'with valid attributes' do
      it 'updates the payment' do
        patch admin_payment_path(payment), params: {
          payment: {
            total_cents: 75.00, # euros, controller converts to 7500 centimes
            payment_method: 'card',
            status: 'success'
          }
        }

        payment.reload
        expect(payment.total_cents).to eq(7500) # in cents
        expect(payment.payment_method).to eq('card')
      end

      it 'converts euros to cents' do
        patch admin_payment_path(payment), params: {
          payment: {
            total_cents: 100.75,
            payment_method: 'cash',
            status: 'success'
          }
        }

        payment.reload
        expect(payment.total_cents).to eq(10_075)
      end

      it 'redirects with success notice' do
        patch admin_payment_path(payment), params: {
          payment: {
            total_cents: 75.00, # euros
            payment_method: 'cash',
            status: 'success'
          }
        }

        expect(response).to redirect_to(admin_payments_path)
      end

      it 'updates offer_reason' do
        patch admin_payment_path(payment), params: {
          payment: {
            payment_method: 'offered',
            offer_reason: 'Solidarity',
            status: 'success'
          }
        }

        payment.reload
        expect(payment.payment_method).to eq('offered')
        expect(payment.offer_reason).to eq('Solidarity')
      end
    end

    context 'with invalid attributes' do
      it 'does not update the payment' do
        original_cents = payment.total_cents

        patch admin_payment_path(payment), params: {
          payment: {
            total_cents: -100
          }
        }

        payment.reload
        expect(payment.total_cents).to eq(original_cents)
      end

      it 'redirects to show and then to index with message' do
        patch admin_payment_path(payment), params: {
          payment: {
            total_cents: -100
          }
        }

        expect(response).to redirect_to(admin_payment_path(payment))
        follow_redirect!
        expect(response).to redirect_to(admin_payments_path)
        follow_redirect!
        # The flash from show action overwrites the error message
        expect(response.body).to include('édition inline')
      end
    end
  end

  describe 'DELETE /admin/payments/:id' do
    let(:admin) { create(:user, :admin) }
    let(:person) { create(:person) }
    let!(:payment) { create(:payment, person: person, recorded_by: admin, total_cents: 5000, status: :success) }

    before { login_as(admin) }

    it 'marks payment as cancelled' do
      expect do
        delete admin_payment_path(payment)
      end.to change { payment.reload.status }.from('success').to('cancel')

      expect(payment.cancelled?).to be_truthy
    end

    it 'creates audit log entry' do
      expect do
        delete admin_payment_path(payment)
      end.to change { PaymentAuditLog.count }.by(1)

      audit_log = PaymentAuditLog.last
      expect(audit_log.payment_id).to eq(payment.id)
      expect(audit_log.user_id).to eq(admin.id)
    end

    it 'redirects with success notice' do
      delete admin_payment_path(payment)
      expect(response).to redirect_to(admin_payments_path)
      follow_redirect!
      expect(response.body).to include('annulé')
    end
  end

  describe 'POST /admin/payments/:id/restore' do
    let(:admin) { create(:user, :admin) }
    let(:person) { create(:person) }

    before { login_as(admin) }

    it 'restores a cancelled payment and returns success' do
      payment = create(:payment, person: person, recorded_by: admin, total_cents: 3200, status: :cancel, notes: 'Cancelled earlier')

      expect do
        post restore_admin_payment_path(payment)
      end.to change { payment.reload.status }.from('cancel').to('success')
                                             .and change { PaymentAuditLog.count }.by(1)

      expect(response).to redirect_to(admin_payment_path(payment))

      payment.reload
      expect(payment.notes).to include('Restored')
    end

    it 'fails gracefully when payment is not cancelled' do
      payment = create(:payment, person: person, recorded_by: admin, total_cents: 2500, status: :success)

      expect do
        post restore_admin_payment_path(payment)
      end.not_to(change { payment.reload.status })

      expect(response).to redirect_to(admin_payments_path)
      follow_redirect!
      expect(response.body).to include('Échec')
    end
  end

  describe 'GET /admin/payments/:id/show' do
    let(:admin) { create(:user, :admin) }
    let(:person) { create(:person) }
    let(:payment) { create(:payment, person: person, recorded_by: admin) }

    before { login_as(admin) }

    it 'redirects to payments index with notice' do
      get admin_payment_path(payment)
      expect(response).to redirect_to(admin_payments_path)
    end
  end
end
