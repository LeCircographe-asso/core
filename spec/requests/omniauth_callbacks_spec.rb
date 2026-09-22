# frozen_string_literal: true

require "rails_helper"

RSpec.describe "OmniauthCallbacks", type: :request do
  describe "GET /auth/google_oauth2/callback" do
    context "when no account exists for this email" do
      it "creates a Person + User and signs the visitor in" do
        mock_google_auth(email: "nouveau.membre@example.com")

        expect {
          get "/auth/google_oauth2/callback"
        }.to change(User, :count).by(1).and change(Person, :count).by(1)

        user = User.find_by(email_address: "nouveau.membre@example.com")
        expect(user).to be_present
        expect(user.provider).to eq("google_oauth2")
        expect(user.uid).to eq("1234567890")
        expect(user.web_visitor?).to be true
        expect(response).to redirect_to(root_path)
        expect(cookies[:session_id]).to be_present
      end
    end

    context "when a User already has this provider/uid" do
      it "signs the existing user in without creating a duplicate" do
        person = create(:person, email: "membre@example.com")
        user = create(:user, person: person, email_address: "membre@example.com", provider: "google_oauth2", uid: "1234567890")
        mock_google_auth(email: "membre@example.com")

        expect { get "/auth/google_oauth2/callback" }.not_to change(User, :count)

        expect(response).to redirect_to(root_path)
        expect(user.reload.sessions.count).to eq(1)
      end
    end

    context "when a Person exists with this email but has no web account yet" do
      it "links the Google identity to that Person instead of duplicating it" do
        person = create(:person, email: "adherent@example.com")
        mock_google_auth(email: "adherent@example.com")

        expect {
          get "/auth/google_oauth2/callback"
        }.to change(User, :count).by(1).and change(Person, :count).by(0)

        expect(person.reload.user).to be_present
        expect(person.user.provider).to eq("google_oauth2")
      end
    end

    context "when a User already exists for this email but without a linked Person identity" do
      it "links the Google identity on first sign-in" do
        person = create(:person, email: "deja.web@example.com")
        user = create(:user, person: person, email_address: "deja.web@example.com")
        mock_google_auth(email: "deja.web@example.com")

        expect { get "/auth/google_oauth2/callback" }.not_to change(User, :count)

        expect(user.reload.provider).to eq("google_oauth2")
        expect(user.uid).to eq("1234567890")
      end
    end

    context "when public registration is disabled and no account exists" do
      it "refuses to create a new account" do
        allow(Rails.application.config.x).to receive(:public_registration_enabled).and_return(false)
        mock_google_auth(email: "inconnu@example.com")

        expect { get "/auth/google_oauth2/callback" }.not_to change(User, :count)

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /auth/failure" do
    it "redirects to the sign-in page with an alert" do
      get "/auth/failure"

      expect(response).to redirect_to(new_session_path)
      expect(flash[:alert]).to include("Google")
    end
  end
end
