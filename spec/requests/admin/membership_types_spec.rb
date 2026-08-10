# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::MembershipTypes", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:volunteer) { create(:user, :volunteer) }

  before { login_as(admin) }

  describe "GET /admin/membership_types/new" do
    it "renders the rate_kind choices in the form" do
      get new_admin_membership_type_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Tarif standard")
      expect(response.body).to include("Tarif réduit")
    end

    it "is forbidden for a volunteer" do
      login_as(volunteer)
      get new_admin_membership_type_path

      expect(response).to redirect_to(admin_dashboard_index_path)
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

  describe "PATCH /admin/membership_types/:id" do
    it "updates the description" do
      membership_type = create(:membership_type, description: "Old description")

      patch admin_membership_type_path(membership_type), params: {
        membership_type: { description: "New description" }
      }

      expect(response).to redirect_to(admin_membership_types_path)
      expect(membership_type.reload.description).to eq("New description")
    end

    it "ignores structural/pricing fields — they only go through #change_price" do
      membership_type = create(:membership_type, price_cents: 1000, category: "basic", rate_kind: "standard")

      patch admin_membership_type_path(membership_type), params: {
        membership_type: { price_cents: 9999, category: "circus", rate_kind: "reduced" }
      }

      membership_type.reload
      expect(membership_type.price_cents).to eq(1000)
      expect(membership_type.category).to eq("basic")
      expect(membership_type.rate_kind).to eq("standard")
    end
  end

  describe "POST /admin/membership_types/:id/change_price" do
    it "merges the price in place when the type was never sold" do
      membership_type = create(:membership_type, price_cents: 1000)

      expect do
        post change_price_admin_membership_type_path(membership_type), params: { price: "15.00", reason: "Correction" }
      end.not_to change(MembershipType, :count)

      expect(response).to redirect_to(admin_membership_types_path)
      expect(membership_type.reload.price_cents).to eq(1500)
    end

    it "creates a new version when the type has already been sold" do
      membership_type = create(:membership_type, price_cents: 1000)
      create(:membership, membership_type: membership_type)

      expect do
        post change_price_admin_membership_type_path(membership_type), params: { price: "15.00" }
      end.to change(MembershipType, :count).by(1)

      expect(membership_type.reload.price_cents).to eq(1000)
      expect(MembershipType.current_versions.find_by(name: membership_type.name).price_cents).to eq(1500)
    end
  end

  describe "POST /admin/membership_types/:id/archive" do
    it "closes the version and moves it from the catalog listing to the archived list" do
      membership_type = create(:membership_type, name: "Adhésion Test Archive")

      post archive_admin_membership_type_path(membership_type)

      expect(response).to redirect_to(admin_membership_types_path)
      expect(membership_type.reload.current_version?).to be false

      get admin_membership_types_path
      expect(assigns(:membership_types)).not_to include(membership_type)
      expect(assigns(:archived_membership_types)).to include(membership_type)
    end

    it "is forbidden for a volunteer" do
      membership_type = create(:membership_type, name: "Adhésion Test Archive")
      login_as(volunteer)

      post archive_admin_membership_type_path(membership_type)

      expect(membership_type.reload.current_version?).to be true
    end
  end

  describe "POST /admin/membership_types/:id/unarchive" do
    it "reopens the version and moves it back to the catalog listing" do
      membership_type = create(:membership_type, name: "Adhésion Test Unarchive")
      membership_type.archive!(user: admin)

      post unarchive_admin_membership_type_path(membership_type)

      expect(response).to redirect_to(admin_membership_types_path)
      expect(membership_type.reload.current_version?).to be true

      get admin_membership_types_path
      expect(assigns(:membership_types)).to include(membership_type)
      expect(assigns(:archived_membership_types)).not_to include(membership_type)
    end

    it "is forbidden for a volunteer" do
      membership_type = create(:membership_type, name: "Adhésion Test Unarchive")
      membership_type.archive!(user: admin)
      login_as(volunteer)

      post unarchive_admin_membership_type_path(membership_type)

      expect(membership_type.reload.current_version?).to be false
    end
  end
end
