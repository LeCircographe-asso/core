# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::HealthReports', type: :request do
  let(:admin) { create(:user, :admin) }

  before { login_as(admin) }

  it 'renders the health report' do
    create(:user)
    create(:person)

    get admin_health_reports_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Rapport d&#39;intégrité")
    expect(response.body).to include('Utilisateurs sans Person')
    expect(response.body).to include('Paiements sans ligne')
    expect(response.body).to include('Totaux incohérents')
    expect(response.body).to include('Lignes don legacy')
    expect(response.body).to include('Cotisations incoherentes')
  end
end
