# frozen_string_literal: true

require "rails_helper"
require "cgi"

RSpec.describe "Admin::Contributions", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:person) { create(:person, :with_circus_membership) }
  let(:from_formula) { create(:contribution_formula, :pack10) }
  let(:to_formula) { create(:contribution_formula, :trimester) }
  let(:formula) { create(:contribution_formula, :pack10, membership_type: person.current_membership.membership_type, price_cents: 2_500) }
  let!(:existing_contribution) do
    People::ContributionCreator.new(
      person: person,
      contribution_formula_id: from_formula.id,
      payment_method: "cash",
      recorded_by_id: admin.id
    ).call.contribution
  end

  before { login_as(admin) }

  describe "GET /admin/contributions/new" do
    before { formula }

    it "keeps the person context in breadcrumbs and return link" do
      get new_admin_contribution_path(person_id: person.id)

      expect(response).to have_http_status(:success)
      expect(response.body).to include(person.full_name)
      expect(response.body).to include(admin_member_path(person))
    end

    it "renders a single purchase form for all available formulas" do
      create(:contribution_formula, :annual, membership_type: person.current_membership.membership_type)

      get new_admin_contribution_path(person_id: person.id)

      document = Nokogiri::HTML.parse(response.body)
      forms = document.css("form[action='#{admin_contributions_path}']")
      formula_inputs = document.css("input[type='radio'][name='contribution[contribution_formula_id]']")

      expect(forms.count).to eq(1)
      expect(formula_inputs.count).to eq(2)
    end

    it "renders a compact checkout block with business constraint" do
      get new_admin_contribution_path(person_id: person.id)

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

      get new_admin_contribution_path(person_id: person.id)

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

      get new_admin_contribution_path(person_id: person.id)

      expect(CGI.unescapeHTML(response.body)).to include("Déjà une journée active aujourd'hui")
    end

    it "redirects when no person is given" do
      get new_admin_contribution_path

      expect(response).to redirect_to(admin_members_path)
    end
  end

  describe "POST /admin/contributions" do
    it "creates a contribution payment with contribution and donation lines" do
      expect do
        post admin_contributions_path, params: {
          person_id: person.id,
          contribution: {
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

      post admin_contributions_path, params: {
        person_id: person.id,
        contribution: {
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

  describe "POST /admin/contributions/upgrade" do
    it "upgrades using canonical params" do
      expect do
        post upgrade_admin_contributions_path, params: {
          person_id: person.id,
          from_contribution_id: existing_contribution.id,
          to_formula_id: to_formula.id,
          payment_method: "cash"
        }
      end.to change(Payment, :count).by(1)

      expect(response).to redirect_to(admin_member_path(person))
      expect(person.reload.contributions.order(:created_at).last.contribution_formula).to eq(to_formula)
    end

    it "upgrades using legacy from_book_id and to_plan_id params" do
      expect do
        post upgrade_admin_contributions_path, params: {
          person_id: person.id,
          from_book_id: existing_contribution.id,
          to_plan_id: to_formula.id,
          payment_method: "cash"
        }
      end.to change(Payment, :count).by(1)

      expect(response).to redirect_to(admin_member_path(person))
      expect(person.reload.contributions.order(:created_at).last.contribution_formula).to eq(to_formula)
    end
  end
end
