# frozen_string_literal: true

require "rails_helper"
require "cgi"

RSpec.describe "Admin::Contributions", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:admin) { create(:user, :admin) }
  let(:person) { create(:person, :with_circus_membership) }
  let(:from_formula) { create(:contribution_formula, :pack10) }
  let(:to_formula) { create(:contribution_formula, :trimester) }
  let(:formula) { create(:contribution_formula, :pack10, membership_type: person.current_membership.membership_type, price_cents: 2_500) }

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

    it "creates a shared payment covering an additional beneficiary" do
      other_person = create(:person, :with_circus_membership)

      # Le vrai formulaire soumet un index numérique explicite par ligne
      # (contribution[beneficiaries][0][...]), que Rails parse en Hash, pas en Array —
      # cf. incident : un Array ne reproduit pas la vraie forme envoyée par le navigateur.
      expect do
        post admin_contributions_path, params: {
          person_id: person.id,
          contribution: {
            contribution_formula_id: formula.id,
            payment_method: "cash",
            beneficiaries: {
              "0" => { person_id: other_person.id, contribution_formula_id: formula.id, record_attendance: "0" }
            }
          }
        }
      end.to change(Contribution, :count).by(2).and change(Payment, :count).by(1)

      payment = Payment.order(:created_at).last

      expect(response).to redirect_to(admin_member_path(person))
      expect(payment.person).to eq(person)
      expect(payment.total_cents).to eq(formula.price_cents * 2)
      expect(person.reload.contributions.order(:created_at).last.person).to eq(person)
      expect(other_person.reload.contributions.order(:created_at).last.person).to eq(other_person)
    end

    it "fails loudly instead of silently dropping a beneficiary row without a selected person" do
      contribution_count_before = Contribution.count
      payment_count_before = Payment.count

      post admin_contributions_path, params: {
        person_id: person.id,
        contribution: {
          contribution_formula_id: formula.id,
          payment_method: "cash",
          beneficiaries: {
            "0" => { person_id: "", contribution_formula_id: formula.id, record_attendance: "0" }
          }
        }
      }

      expect(Contribution.count).to eq(contribution_count_before)
      expect(Payment.count).to eq(payment_count_before)
      expect(response).to redirect_to(new_admin_contribution_path(person_id: person.id))
      follow_redirect!
      expect(response.body).to include("bénéficiaire additionnel")
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

    it "keeps the purchase but warns visibly when attendance cannot be recorded (training closed)" do
      travel_to Date.current.next_occurring(:monday).beginning_of_day + 12.hours do
        expect do
          post admin_contributions_path, params: {
            person_id: person.id,
            contribution: { contribution_formula_id: formula.id, payment_method: "cash", record_attendance: "1" }
          }
        end.to change(Contribution, :count).by(1)

        expect(response).to redirect_to(admin_member_path(person))
        follow_redirect!
        expect(response.body).to include("présence non enregistrée")
      end
    end

    it "blocks a purchase when the person already has an active contribution (garde-fou anti-doublon)" do
      post admin_contributions_path, params: {
        person_id: person.id,
        contribution: { contribution_formula_id: formula.id, payment_method: "cash" }
      }

      contribution_count_before = Contribution.count
      payment_count_before = Payment.count

      post admin_contributions_path, params: {
        person_id: person.id,
        contribution: { contribution_formula_id: create(:contribution_formula, :day).id, payment_method: "cash" }
      }

      expect(Contribution.count).to eq(contribution_count_before)
      expect(Payment.count).to eq(payment_count_before)
      expect(response).to redirect_to(new_admin_contribution_path(person_id: person.id))
      follow_redirect!
      expect(response.body).to include("a déjà une cotisation active")
    end
  end

  describe "GET /admin/contributions/beneficiary_search" do
    it "finds people by name and excludes the given ids" do
      match = create(:person, :with_circus_membership, first_name: "Camille", last_name: "Durand")
      excluded = create(:person, :with_circus_membership, first_name: "Camille", last_name: "Autre")
      create(:person, :with_circus_membership, first_name: "Someone", last_name: "Else")

      get beneficiary_search_admin_contributions_path, params: { person_id: person.id, q: "Camille", exclude_ids: [ excluded.id ] }

      expect(response).to have_http_status(:success)
      expect(response.body).to include(match.full_name)
      expect(response.body).not_to include(excluded.full_name)
    end

    it "excludes people without an active circus membership (garde-fou métier)" do
      basic_membership_type = create(:membership_type, category: :basic)
      ineligible = create(:person, first_name: "Camille", last_name: "SansCirque")
      create(:membership, person: ineligible, membership_type: basic_membership_type, status: :active)

      get beneficiary_search_admin_contributions_path, params: { person_id: person.id, q: "Camille" }

      expect(response.body).not_to include(ineligible.full_name)
    end

    it "excludes the payer from results" do
      get beneficiary_search_admin_contributions_path, params: { person_id: person.id, q: person.first_name }

      expect(response.body).not_to include(person.full_name)
    end

    it "returns nothing for a query shorter than 2 characters" do
      create(:person, first_name: "A")

      get beneficiary_search_admin_contributions_path, params: { person_id: person.id, q: "a" }

      expect(response.body).to include("Aucun résultat")
    end
  end

  describe "POST /admin/contributions/upgrade" do
    # Scopé ici (pas au niveau du describe racine) : depuis le garde-fou anti-doublon dans
    # ContributionCreator, une cotisation active préexistante bloquerait les tests POST
    # /admin/contributions "normaux" ailleurs dans ce fichier — seul le flux upgrade doit
    # partir d'une personne qui a déjà une cotisation active.
    let!(:existing_contribution) do
      People::ContributionCreator.new(
        person: person,
        contribution_formula_id: from_formula.id,
        payment_method: "cash",
        recorded_by_id: admin.id
      ).call.contribution
    end

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
