# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::Exports', type: :request do
  describe 'access control' do
    context 'as a volunteer' do
      let(:volunteer) { create(:user, :volunteer) }

      before { login_as(volunteer) }

      it 'blocks the exports index' do
        get admin_exports_path
        expect(response).to redirect_to(admin_dashboard_index_path)
      end

      it 'blocks the all_users CSV export' do
        get all_users_admin_exports_path
        expect(response).to redirect_to(admin_dashboard_index_path)
      end

      it 'blocks the newsletter CSV export' do
        get newsletter_subscribed_admin_exports_path
        expect(response).to redirect_to(admin_dashboard_index_path)
      end

      it 'blocks CRM exports' do
        get admin_export_path('payment_lines', format: :csv)
        expect(response).to redirect_to(admin_dashboard_index_path)
      end
    end

    context 'as an admin' do
      let(:admin) { create(:user, :admin) }

      before { login_as(admin) }

      it 'allows the all_users CSV export' do
        create(:person, first_name: 'Alice', last_name: 'Martin')

        get all_users_admin_exports_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Alice')
      end

      it 'lists CRM exports on the index' do
        get admin_exports_path

        expect(response.body).to include(admin_export_path('attendances', format: :csv))
      end

      it 'downloads a versioned CRM export for the period and audits it' do
        create(:attendance, date: Date.new(2026, 1, 10))
        allow(Rails.logger).to receive(:info).and_call_original

        get admin_export_path('attendances', format: :csv, from: '2026-01-01', to: '2026-01-31')

        expect(response).to have_http_status(:success)
        expect(response.headers['Content-Disposition']).to include('attendances_v1_2026-01-01_2026-01-31_')
        expect(response.body.lines.size).to eq(2)
        expect(Rails.logger).to have_received(:info).with(/\[export\.audit\] user_id=#{admin.id} export=attendances version=1 .* rows=1/)
      end

      it 'returns 404 for an unknown export' do
        get admin_export_path('unknown', format: :csv)

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
