# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Roles", type: :request do
  let(:admin) { create(:user, :admin) }

  describe "GET /admin/roles" do
    it "lists accounts with a role, not web visitors" do
      volunteer = create(:user, :volunteer)
      web_visitor = create(:user)
      login_as(admin)

      get admin_roles_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(volunteer.email_address)
      expect(response.body).not_to include(web_visitor.email_address)
    end

    it "finds web visitors to promote by name" do
      person = create(:person, first_name: "Zéphyrine", last_name: "Trapèze")
      web_visitor = create(:user, person: person)
      login_as(admin)

      get admin_roles_path, params: { search: "Trapèze" }

      expect(response.body).to include(web_visitor.email_address)
    end

    it "keeps volunteers out" do
      login_as(create(:user, :volunteer))

      get admin_roles_path

      expect(response).to redirect_to(admin_dashboard_index_path)
    end
  end
end
