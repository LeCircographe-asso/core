# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::Dashboard', type: :request do
  describe 'GET /admin/dashboard' do
    context 'when not authenticated' do
      it 'redirects to login' do
        get admin_dashboard_index_path
        expect(response).to redirect_to(new_session_path)
      end
    end

    context 'when authenticated as web_visitor' do
      let(:user) { create(:user, system_role: :web_visitor) }

      before { login_as(user) }

      it 'redirects to root with alert' do
        get admin_dashboard_index_path
        expect(response).to redirect_to(root_path)
      end
    end

    context 'when authenticated as volunteer' do
      let(:volunteer) { create(:user, :volunteer) }

      before { login_as(volunteer) }

      it 'returns http success' do
        get admin_dashboard_index_path
        expect(response).to have_http_status(:success)
      end
    end

    context 'when authenticated as admin' do
      let(:admin) { create(:user, :admin) }

      before { login_as(admin) }

      it 'returns http success' do
        get admin_dashboard_index_path
        expect(response).to have_http_status(:success)
      end

      it 'loads cached notepad' do
        Rails.cache.write('notepad', 'Test notepad content')

        get admin_dashboard_index_path
        expect(response).to have_http_status(:success)
      end

      it 'loads opening_hours from the database' do
        create(:opening_hour, day: :mardi, open_at: '09:00', close_at: '17:00', updated_by_user: admin)

        get admin_dashboard_index_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include('09:00 - 17:00')
      end
    end
  end
end
