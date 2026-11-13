# frozen_string_literal: true

require "rails_helper"

# Requêtes visiteur (non connecté·e) mal formées ou sur d'anciennes routes : elles doivent
# rediriger proprement, jamais finir en 500/400 brute (qui crée aussi un BugReport automatique).
RSpec.describe "Visitor hardening", type: :request do
  describe "POST /session with blank fields" do
    it "redirects back to the login form with the invalid credentials alert" do
      post session_path, params: { email_address: "", password: "" }

      expect(response).to redirect_to(new_session_path)
      expect(flash[:alert]).to eq(I18n.t("sessions.create.invalid_credentials_redirect"))
    end

    it "handles missing params the same way" do
      post session_path

      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "legacy change_newsletter_status as a guest" do
    it "redirects GET to the login page" do
      get change_newsletter_status_user_path(1)

      expect(response).to redirect_to(new_session_path)
    end

    it "redirects POST to the login page" do
      post change_newsletter_status_user_path(1)

      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "POST /newsletter_signup without the user param" do
    it "redirects with the blank email alert instead of crashing" do
      post newsletter_signup_path

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be_present
    end
  end

  describe "GET /service-worker with an HTML Accept header" do
    it "still serves the JavaScript file" do
      get "/service-worker", headers: { "Accept" => "text/html" }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/javascript")
    end
  end
end
