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
    end
  end
end
