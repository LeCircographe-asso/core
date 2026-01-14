require "rails_helper"

RSpec.describe "Admin::HealthReports", type: :request do
  let(:admin) { create(:user, :admin) }

  before { login_as(admin) }

  it "renders the health report" do
    create(:user)
    create(:person)

    get admin_health_reports_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Rapport d'integrite")
    expect(response.body).to include("Utilisateurs sans Person")
  end
end
