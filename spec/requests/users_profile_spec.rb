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
      expect(response.body).to include('id="overview"')
      expect(response.body).to include('id="contact"')
      expect(response.body).not_to include('id="account"')
      expect(response.body).to include(page_path("faq"))
      expect(response.body).to include("Adhérer")
      expect(response.body).to include(page_path("become_member"))
      expect(response.body).to include("Pas d'adhésion en cours")
      expect(response.body).not_to include("Renouveler mon adhésion")
      expect(response.body).not_to include(I18n.t("users.space.membership_card_settings_link"))
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
      expect(response.body).to match(/Adhésion valable jusqu/)
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

  describe "GET /users/:id/edit" do
    let(:user) { create(:user) }

    before { login_as(user) }

    it "redirects to mon espace with the coordinates anchor" do
      get edit_user_path(user)
      expect(response).to have_http_status(:see_other)
      expect(response.location).to end_with("#{user_path(user)}#contact")
    end
  end

  describe "PATCH /users/:id" do
    let(:person_without_membership) { create(:person, :without_membership, phone: nil, address: nil) }
    let(:user) { create(:user, person: person_without_membership) }

    before { login_as(user) }

    it "updates postal coordinates and lands on the contact section" do
      patch user_path(user), params: {
        user: {
          phone: "0612345678",
          address: "1 rue du Cirque",
          zip_code: "75001",
          town: "Paris",
          country: "France"
        }
      }

      expect(response).to be_redirect
      expect(response.location).to end_with("#{user_path(user)}#contact")
      follow_redirect!
      expect(response.body).to include(I18n.t("users.update.coordinates_updated"))

      person_without_membership.reload
      expect(person_without_membership.phone).to eq("0612345678")
      expect(person_without_membership.address).to eq("1 rue du Cirque")
      expect(person_without_membership.zip_code).to eq("75001")
      expect(person_without_membership.town).to eq("Paris")
      expect(person_without_membership.country).to eq("France")
    end

    it "returns turbo-stream replacements for the contact section and flash" do
      patch user_path(user),
            params: {
              user: {
                phone: "0612345678",
                address: "1 rue du Cirque",
                zip_code: "75001",
                town: "Paris",
                country: "France"
              }
            },
            headers: { "Accept" => Mime[:turbo_stream].to_s }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq(Mime[:turbo_stream])
      expect(response.body).to include(%(target="#{ProfileSectionDomIds::CONTACT_SECTION}"))
      expect(response.body).to include(%(target="#{ProfileSectionDomIds::FLASH_FRAME}"))
    end
  end
end
