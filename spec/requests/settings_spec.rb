# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Settings", type: :request do
  describe "GET /settings" do
    let(:user) { create(:user) }

    before { login_as(user) }

    it "redirects to the profile page anchored on account settings" do
      get settings_path

      expect(response).to have_http_status(:see_other)
      expect(response.location).to end_with("#{user_path(user)}#account")
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

    it "updates preferences and redirects back to profile account anchor with notice" do
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

      expect(response).to have_http_status(:see_other)
      expect(response.location).to end_with("#{user_path(user)}#account")
      follow_redirect!
      expect(response.body).to include(I18n.t("settings.update.saved_notice"))
    end
  end
end
