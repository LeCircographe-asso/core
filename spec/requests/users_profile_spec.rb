# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User profile (users#show)", type: :request do
  describe "GET /users/:id" do
    let(:person_without_membership) { create(:person, :without_membership, first_name: "Ada", last_name: "Lovelace") }
    let(:user) { create(:user, person: person_without_membership) }

    before { login_as(user) }

    it "shows adhesion CTA for a user without membership history" do
      get user_path(user)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Accès rapide")
      expect(response.body).to include(edit_user_path(user))
      expect(response.body).to include(page_path("faq"))
      expect(response.body).to include("Adhérer")
      expect(response.body).to include(page_path("become_member"))
      expect(response.body).to include("Pas d'adhésion en cours")
      expect(response.body).not_to include("Renouveler mon adhésion")
    end

    it "shows renewal CTA and lapsed copy when the last membership is over" do
      create(:membership, person: person_without_membership, membership_type: create(:membership_type, :basic),
                          started_at: 2.years.ago, ended_at: 1.month.ago, status: :expired)

      get user_path(user)
      expect(response.body).to include("Adhésion terminée")
      expect(response.body).to include("Renouveler mon adhésion")
      expect(response.body).to include("Fin de la dernière adhésion")
    end

    it "shows active membership and cotisation summary for a circus member" do
      circus_person = create(:person, :with_circus_membership)
      circus_user = create(:user, person: circus_person)
      login_as(circus_user)

      get user_path(circus_user)
      expect(response.body).to include("Adhésion active")
      expect(response.body).to include("Cotisations actives")
      expect(response.body).to include("Aucune cotisation active")
      expect(response.body).to include("Adhésion valable jusqu'au")
      expect(response.body).not_to include("Renouveler mon adhésion")
    end

    it "links privileged users to the administration area" do
      staff_person = create(:person)
      staff_user = create(:user, :admin, person: staff_person)
      login_as(staff_user)

      get user_path(staff_user)
      expect(response.body).to include("Espace administration")
      expect(response.body).to include(admin_root_path)
    end

    it "does not show the administration link to standard visitors" do
      get user_path(user)
      expect(response.body).not_to include("Espace administration")
    end
  end
end
