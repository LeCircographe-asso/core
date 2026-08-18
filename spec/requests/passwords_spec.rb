# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Passwords", type: :request do
  describe "GET /passwords/new" do
    it "renders the reset request page" do
      get new_password_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /passwords" do
    it "enqueues a reset email for an existing account" do
      user = create(:user)

      expect do
        post passwords_path, params: { email_address: user.email_address }
      end.to have_enqueued_mail(PasswordsMailer, :reset).with(user)

      expect(response).to redirect_to(new_session_path)
    end

    it "does not reveal unknown email addresses" do
      expect do
        post passwords_path, params: { email_address: "missing@example.com" }
      end.not_to have_enqueued_mail(PasswordsMailer, :reset)

      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "PATCH /passwords/:token" do
    it "updates the password with a valid token" do
      user = create(:user, password: "old-password", password_confirmation: "old-password")
      token = user.generate_token_for(:password_reset)

      patch password_path(token), params: {
        password: "new-password",
        password_confirmation: "new-password"
      }

      expect(response).to redirect_to(new_session_path)
      expect(user.reload.authenticate("new-password")).to eq(user)
    end

    it "renders edit when password confirmation is invalid" do
      user = create(:user)
      token = user.generate_token_for(:password_reset)

      patch password_path(token), params: {
        password: "new-password",
        password_confirmation: "different"
      }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "redirects invalid tokens to the reset request page" do
      patch password_path("invalid-token"), params: {
        password: "new-password",
        password_confirmation: "new-password"
      }

      expect(response).to redirect_to(new_password_path)
    end
  end

  describe "GET /password/request_reset" do
    it "enqueues a reset email for the signed-in user" do
      user = create(:user)
      login_as(user)

      expect do
        get request_reset_passwords_path
      end.to have_enqueued_mail(PasswordsMailer, :reset).with(user)

      expect(response).to redirect_to(user_path(user))
    end

    it "redirects guests to sign in" do
      get request_reset_passwords_path

      expect(response).to redirect_to(new_session_path)
    end
  end
end
