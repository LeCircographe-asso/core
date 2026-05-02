# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::MembershipTypes", type: :request do
  let(:admin) { create(:user, :admin) }

  before { login_as(admin) }

  describe "GET /admin/membership_types/new" do
    it "renders the rate_kind choices in the form" do
      get new_admin_membership_type_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Tarif standard")
      expect(response.body).to include("Tarif réduit")
    end
  end

  describe "GET /admin/membership_types" do
    it "shows the rate_kind badge in the catalog" do
      create(:membership_type, :circus, name: "Adhésion Cirque Solidaire", rate_kind: "reduced")

      get admin_membership_types_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Tarif réduit")
    end
  end

  describe "POST /admin/membership_types" do
    it "persists the selected rate_kind" do
      post admin_membership_types_path, params: {
        membership_type: {
          name: "Adhésion Cirque Solidaire",
          category: "circus",
          rate_kind: "reduced",
          price_cents: 1700,
          description: "Adhésion à tarif réduit",
          effective_from: Date.current,
          version: 1
        }
      }

      membership_type = MembershipType.order(:created_at).last

      expect(response).to redirect_to(admin_membership_types_path)
      expect(membership_type.rate_kind).to eq("reduced")
    end
  end
end
