# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::DonationReceipts', type: :request do
  let(:admin) { create(:user, :admin) }
  let(:payment) { create(:payment, status: :success) }
  let!(:donation_line) do
    create(:payment_line, payment: payment, item_type: 'Donation', item_id: payment.id, amount_cents: 1000, description: 'Don libre')
  end

  before { login_as(admin) }

  describe 'GET /admin/payments (row action rendering)' do
    it 'shows an issue-receipt button for a donation without a receipt yet' do
      get admin_payments_path

      expect(response.body).to include(admin_payment_donation_receipt_path(payment))
    end

    it 'shows a download link once a receipt has been issued' do
      People::DonationReceiptIssuer.new(payment_line: donation_line).call

      get admin_payments_path

      expect(response.body).to include(admin_payment_donation_receipt_path(payment))
      expect(response.body).to include(resend_admin_payment_donation_receipt_path(payment))
    end
  end

  describe 'POST /admin/payments/:payment_id/donation_receipt' do
    it 'issues a receipt and redirects back to the payments list' do
      expect do
        post admin_payment_donation_receipt_path(payment)
      end.to change(DonationReceipt, :count).by(1)

      expect(response).to redirect_to(admin_payments_path(person_id: payment.person_id, anchor: "payment_row_#{payment.id}"))
      expect(flash[:notice]).to be_present
    end

    it 'redirects with an alert when the payment has no donation line' do
      other_payment = create(:payment, status: :success)

      post admin_payment_donation_receipt_path(other_payment)

      expect(response).to redirect_to(admin_payments_path(person_id: other_payment.person_id, anchor: "payment_row_#{other_payment.id}"))
      expect(flash[:alert]).to be_present
    end
  end

  describe 'GET /admin/payments/:payment_id/donation_receipt' do
    it 'redirects with an alert when no receipt has been issued yet' do
      get admin_payment_donation_receipt_path(payment)

      expect(response).to redirect_to(admin_payments_path(person_id: payment.person_id, anchor: "payment_row_#{payment.id}"))
      expect(flash[:alert]).to be_present
    end

    it 'streams a PDF once a receipt exists' do
      People::DonationReceiptIssuer.new(payment_line: donation_line).call

      get admin_payment_donation_receipt_path(payment)

      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/pdf')
      expect(response.body.byteslice(0, 5)).to eq('%PDF-')
    end
  end

  describe 'POST /admin/payments/:payment_id/donation_receipt/resend' do
    it 'redirects with an alert when no receipt has been issued yet' do
      post resend_admin_payment_donation_receipt_path(payment)

      expect(flash[:alert]).to be_present
    end

    it 'delivers the receipt email once a receipt exists' do
      People::DonationReceiptIssuer.new(payment_line: donation_line).call

      expect do
        post resend_admin_payment_donation_receipt_path(payment)
      end.to have_enqueued_mail(DonationMailer, :receipt_email)

      expect(flash[:notice]).to be_present
    end
  end
end
