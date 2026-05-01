# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Settings", type: :request do
  describe "GET /settings" do
    let(:user) { create(:user) }

    before { login_as(user) }

    it "renders the settings page" do
      get settings_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("settings.show.page_title"))
    end

    it "redirects guests to sign in" do
      logout
      get settings_path
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "PATCH /settings" do
    let(:user) { create(:user) }

    before { login_as(user) }

    it "updates preferences, redirects to settings, and shows the notice" do
      person = user.person

      patch settings_path, params: {
        user: {
          email_address: user.email_address,
          image_rights: person.image_rights ? "1" : "0",
          newsletter_subscribed: person.newsletter_subscribed? ? "1" : "0",
          get_involved: person.get_involved ? "1" : "0",
          dyslexic_font: person.dyslexic_font ? "1" : "0"
        }
      }

      expect(response).to redirect_to(settings_path)
      expect(response).to have_http_status(:see_other)
      follow_redirect!
      expect(response.body).to include(I18n.t("settings.update.saved_notice"))
    end

    it "returns turbo-stream replacements for the account section and flash" do
      person = user.person

      patch settings_path,
            params: {
              user: {
                email_address: user.email_address,
                image_rights: person.image_rights ? "1" : "0",
                newsletter_subscribed: person.newsletter_subscribed? ? "1" : "0",
                get_involved: person.get_involved ? "1" : "0",
                dyslexic_font: person.dyslexic_font ? "1" : "0"
              }
            },
            headers: { "Accept" => Mime[:turbo_stream].to_s }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq(Mime[:turbo_stream])
      expect(response.body).to include(%(target="#{ProfileSectionDomIds::ACCOUNT_SECTION}"))
      expect(response.body).to include(%(target="#{ProfileSectionDomIds::FLASH_FRAME}"))
    end
  end
end
