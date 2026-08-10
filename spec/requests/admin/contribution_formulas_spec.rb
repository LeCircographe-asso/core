# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::ContributionFormulas", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:volunteer) { create(:user, :volunteer) }
  let(:person) { create(:person, :with_circus_membership) }
  let(:formula) { create(:contribution_formula, :pack10, membership_type: person.current_membership.membership_type, price_cents: 2_500) }

  before { login_as(admin) }

  describe "GET /admin/contribution_formulas/new" do
    it "renders the catalog creation form for an admin" do
      get new_admin_contribution_formula_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include('name="contribution_formula[name]"')
      expect(response.body).to include('name="contribution_formula[membership_type_id]"')
    end

    it "is forbidden for a volunteer" do
      login_as(volunteer)
      get new_admin_contribution_formula_path

      expect(response).to redirect_to(admin_dashboard_index_path)
    end
  end

  describe "POST /admin/contribution_formulas" do
    it "creates a new catalog formula" do
      membership_type = person.current_membership.membership_type

      expect do
        post admin_contribution_formulas_path, params: {
          contribution_formula: {
            name: "Trimestre - #{membership_type.name}",
            description: "Accès aux cours pendant 3 mois",
            duration: "trimester",
            rate_kind: "standard",
            membership_type_id: membership_type.id,
            price_cents: 6_000,
            effective_from: Date.current
          }
        }
      end.to change(ContributionFormula, :count).by(1)

      expect(response).to redirect_to(admin_contribution_formulas_path)
      expect(ContributionFormula.order(:created_at).last.price_cents).to eq(6_000)
    end

    it "re-renders the form with errors when invalid" do
      expect do
        post admin_contribution_formulas_path, params: {
          contribution_formula: { name: "", duration: "trimester" }
        }
      end.not_to change(ContributionFormula, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "is forbidden for a volunteer" do
      login_as(volunteer)
      membership_type = person.current_membership.membership_type

      expect do
        post admin_contribution_formulas_path, params: {
          contribution_formula: { name: "X", duration: "trimester", rate_kind: "standard", membership_type_id: membership_type.id, price_cents: 1000, effective_from: Date.current }
        }
      end.not_to change(ContributionFormula, :count)

      expect(response).to redirect_to(admin_dashboard_index_path)
    end
  end

  describe "GET /admin/contribution_formulas/:id/edit" do
    it "is accessible to a plain admin, not only super_admin" do
      get edit_admin_contribution_formula_path(formula)

      expect(response).to have_http_status(:success)
    end

    it "shows the current rate_kind as read-only info, with no editable price/duration/rate_kind fields" do
      get edit_admin_contribution_formula_path(formula)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Tarif standard")
      expect(response.body).not_to include('name="contribution_formula[price_cents]"')
      expect(response.body).not_to include('name="contribution_formula[duration]"')
      expect(response.body).not_to include('name="contribution_formula[rate_kind]"')
    end

    it "is forbidden for a volunteer" do
      login_as(volunteer)
      get edit_admin_contribution_formula_path(formula)

      expect(response).to redirect_to(admin_dashboard_index_path)
    end
  end

  describe "GET /admin/contribution_formulas/:id" do
    it "shows the rate_kind badge in the catalog details" do
      get admin_contribution_formula_path(formula)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Tarif standard")
    end
  end

  describe "PATCH /admin/contribution_formulas/:id" do
    it "updates the description" do
      patch admin_contribution_formula_path(formula), params: {
        contribution_formula: { name: formula.name, description: "Nouvelle description" }
      }

      expect(response).to redirect_to(admin_contribution_formulas_path)
      expect(formula.reload.description).to eq("Nouvelle description")
    end

    it "ignores structural/pricing fields — they only go through #change_price" do
      original_price = formula.price_cents

      patch admin_contribution_formula_path(formula), params: {
        contribution_formula: { name: formula.name, rate_kind: "reduced", price_cents: original_price + 500 }
      }

      formula.reload
      expect(formula.rate_kind).not_to eq("reduced")
      expect(formula.price_cents).to eq(original_price)
    end
  end

  describe "POST /admin/contribution_formulas/:id/change_price" do
    it "merges the price in place when the formula was never sold" do
      formula
      expect do
        post change_price_admin_contribution_formula_path(formula), params: { price: "30.00", reason: "Correction" }
      end.not_to change(ContributionFormula, :count)

      expect(response).to redirect_to(admin_contribution_formulas_path)
      expect(formula.reload.price_cents).to eq(3000)
    end

    it "creates a new version when the formula has already been sold" do
      create(:contribution, contribution_formula: formula, person: create(:person))

      expect do
        post change_price_admin_contribution_formula_path(formula), params: { price: "30.00" }
      end.to change(ContributionFormula, :count).by(1)

      expect(formula.reload.price_cents).to eq(2_500)
    end

    it "is allowed for a plain admin (not only super_admin)" do
      post change_price_admin_contribution_formula_path(formula), params: { price: "30.00" }

      expect(formula.reload.price_cents).to eq(3000)
    end

    it "is forbidden for a volunteer" do
      login_as(volunteer)
      post change_price_admin_contribution_formula_path(formula), params: { price: "30.00" }

      expect(formula.reload.price_cents).to eq(2_500)
    end
  end

  describe "POST /admin/contribution_formulas/:id/archive" do
    it "closes the version and moves it from the catalog listing to the archived list" do
      post archive_admin_contribution_formula_path(formula)

      expect(response).to redirect_to(admin_contribution_formulas_path)
      expect(formula.reload.current_version?).to be false

      get admin_contribution_formulas_path
      expect(assigns(:contribution_formulas)).not_to include(formula)
      expect(assigns(:archived_contribution_formulas)).to include(formula)
    end

    it "is forbidden for a volunteer" do
      login_as(volunteer)
      post archive_admin_contribution_formula_path(formula)

      expect(formula.reload.current_version?).to be true
    end
  end

  describe "POST /admin/contribution_formulas/:id/unarchive" do
    before { formula.archive!(user: admin) }

    it "reopens the version and moves it back to the catalog listing" do
      post unarchive_admin_contribution_formula_path(formula)

      expect(response).to redirect_to(admin_contribution_formulas_path)
      expect(formula.reload.current_version?).to be true

      get admin_contribution_formulas_path
      expect(assigns(:contribution_formulas)).to include(formula)
      expect(assigns(:archived_contribution_formulas)).not_to include(formula)
    end

    it "refuses when a newer version of the same name is already current" do
      newer = formula.dup
      newer.assign_attributes(version: formula.version + 1, effective_from: Date.current, effective_until: nil)
      newer.save!(validate: false)

      post unarchive_admin_contribution_formula_path(formula)

      expect(formula.reload.current_version?).to be false
    end

    it "is forbidden for a volunteer" do
      login_as(volunteer)
      post unarchive_admin_contribution_formula_path(formula)

      expect(formula.reload.current_version?).to be false
    end
  end
end
