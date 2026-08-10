# frozen_string_literal: true

require "rails_helper"
require "cgi"

RSpec.describe "Admin::ContributionFormulas", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:person) { create(:person, :with_circus_membership) }
  let(:formula) { create(:contribution_formula, :pack10, membership_type: person.current_membership.membership_type, price_cents: 2_500) }

  before { login_as(admin) }

  describe "GET /admin/contribution_formulas/new" do
    before { formula }

    it "keeps the person context in breadcrumbs and return link" do
      get new_admin_contribution_formula_path(person_id: person.id)

      expect(response).to have_http_status(:success)
      expect(response.body).to include(person.full_name)
      expect(response.body).to include(admin_member_path(person))
    end

    it "renders a single purchase form for all available formulas" do
      create(:contribution_formula, :annual, membership_type: person.current_membership.membership_type)

      get new_admin_contribution_formula_path(person_id: person.id)

      document = Nokogiri::HTML.parse(response.body)
      forms = document.css("form[action='#{admin_contribution_formulas_path}']")
      formula_inputs = document.css("input[type='radio'][name='contribution_formula[contribution_formula_id]']")

      expect(forms.count).to eq(1)
      expect(formula_inputs.count).to eq(2)
    end

    it "renders a compact checkout block with business constraint" do
      get new_admin_contribution_formula_path(person_id: person.id)

      expect(response.body).to include("Paiement")
      expect(response.body).not_to include("Résumé")
      expect(response.body).to include("10 séances à utiliser sous 365 jours")
    end

    it "shows the person's current membership and active contributions" do
      create(
        :contribution,
        person: person,
        contribution_formula: formula,
        sessions_remaining: 4,
        status: :active
      )

      get new_admin_contribution_formula_path(person_id: person.id)

      expect(response.body).to include("Adhésion")
      expect(response.body).to include(person.current_membership.membership_type.name)
      expect(response.body).to include("Cotisations en cours")
      expect(response.body).to include("Carnet 10 disponible : 4 séances restantes")
    end

    it "warns when a day pass is already active today" do
      day_formula = create(:contribution_formula, :day, membership_type: person.current_membership.membership_type)
      create(
        :contribution,
        person: person,
        contribution_formula: day_formula,
        purchased_at: Time.current,
        expires_at: Time.current.end_of_day,
        sessions_remaining: 1,
        status: :active
      )

      get new_admin_contribution_formula_path(person_id: person.id)

      expect(CGI.unescapeHTML(response.body)).to include("Déjà une journée active aujourd'hui")
    end
  end

  describe "POST /admin/contribution_formulas" do
    it "creates a contribution payment with contribution and donation lines" do
      expect do
        post admin_contribution_formulas_path, params: {
          contribution_formula: {
            person_id: person.id,
            contribution_formula_id: formula.id,
            payment_method: "cash",
            donation_amount: "7.00"
          }
        }
      end.to change(Contribution, :count).by(1)
        .and change(Payment, :count).by(1)

      payment = Payment.order(:created_at).last
      contribution = person.contributions.order(:created_at).last

      expect(response).to redirect_to(admin_member_path(person))
      expect(payment.total_cents).to eq(3_200)
      expect(payment.payment_lines.pluck(:item_type, :item_id, :amount_cents)).to contain_exactly(
        [ "Contribution", contribution.id, 2_500 ],
        [ "Donation", payment.id, 700 ]
      )
    end

    it "creates an offered contribution payment with persisted offer_reason" do
      super_admin = create(:user, :super_admin)
      login_as(super_admin)

      post admin_contribution_formulas_path, params: {
        contribution_formula: {
          person_id: person.id,
          contribution_formula_id: formula.id,
          payment_method: "offered",
          offer_reason: "Solidarity"
        }
      }

      payment = Payment.order(:created_at).last

      expect(response).to redirect_to(admin_member_path(person))
      expect(payment.payment_method).to eq("offered")
      expect(payment.total_cents).to eq(0)
      expect(payment.offer_reason).to eq("Solidarity")
      expect(payment.payment_lines.sole.item_type).to eq("Contribution")
      expect(payment.payment_lines.sole.amount_cents).to eq(0)
    end
  end

  describe "GET /admin/contribution_formulas/:id/edit" do
    let(:super_admin) { create(:user, :super_admin) }

    before { login_as(super_admin) }

    it "shows the current rate_kind as read-only info, with no editable price/duration/rate_kind fields" do
      get edit_admin_contribution_formula_path(formula)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Tarif standard")
      expect(response.body).not_to include('name="contribution_formula[price_cents]"')
      expect(response.body).not_to include('name="contribution_formula[duration]"')
      expect(response.body).not_to include('name="contribution_formula[rate_kind]"')
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
    let(:super_admin) { create(:user, :super_admin) }

    before { login_as(super_admin) }

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
    let(:super_admin) { create(:user, :super_admin) }

    before { login_as(super_admin) }

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

    it "is forbidden for a plain admin (not super_admin)" do
      login_as(admin)
      post change_price_admin_contribution_formula_path(formula), params: { price: "30.00" }

      expect(formula.reload.price_cents).to eq(2_500)
    end
  end

  describe "POST /admin/contribution_formulas/:id/archive" do
    let(:super_admin) { create(:user, :super_admin) }

    before { login_as(super_admin) }

    it "closes the version and moves it from the catalog listing to the archived list" do
      post archive_admin_contribution_formula_path(formula)

      expect(response).to redirect_to(admin_contribution_formulas_path)
      expect(formula.reload.current_version?).to be false

      get admin_contribution_formulas_path
      expect(assigns(:contribution_formulas)).not_to include(formula)
      expect(assigns(:archived_contribution_formulas)).to include(formula)
    end
  end
end
