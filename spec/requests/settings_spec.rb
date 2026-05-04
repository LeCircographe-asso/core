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

    def patch_settings(params)
      patch settings_path, params: params
    end

    def patch_settings_turbo(params)
      patch settings_path, params: params, headers: { "Accept" => Mime[:turbo_stream].to_s }
    end

    it "updates preferences, redirects to settings, and shows the notice" do
      person = user.person

      patch_settings(
        {
        user: {
          email_address: user.email_address,
          image_rights: person.image_rights ? "1" : "0",
          newsletter_subscribed: person.newsletter_subscribed? ? "1" : "0",
          get_involved: person.get_involved ? "1" : "0",
          dyslexic_font: person.dyslexic_font ? "1" : "0"
        }
      }
      )

      expect(response).to redirect_to(settings_path)
      expect(response).to have_http_status(:see_other)
      follow_redirect!
      expect(response.body).to include(I18n.t("settings.update.saved_notice"))
    end

    it "returns turbo-stream replacements for the account section and flash" do
      person = user.person

      patch_settings_turbo(
        {
          user: {
            email_address: user.email_address,
            image_rights: person.image_rights ? "1" : "0",
            newsletter_subscribed: person.newsletter_subscribed? ? "1" : "0",
            get_involved: person.get_involved ? "1" : "0",
            dyslexic_font: person.dyslexic_font ? "1" : "0"
          }
        }
      )

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq(Mime[:turbo_stream])
      expect(response.body).to include(%(target="#{ProfileSectionDomIds::ACCOUNT_SECTION}"))
      expect(response.body).to include(%(target="#{ProfileSectionDomIds::FLASH_FRAME}"))
    end

    it "updates email only when only email_address is submitted (dedicated flow)" do
      new_email = "new-email-#{user.id}@example.com"

      patch_settings(user: { email_address: new_email })

      expect(response).to redirect_to(settings_path)
      expect(user.reload.email_address).to eq(new_email)
    end

    it "returns turbo-stream when updating email only from profile context" do
      new_email = "profile-email-#{user.id}@example.com"

      patch_settings_turbo(
        {
          ui_context: "profile",
          user: { email_address: new_email }
        }
      )

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq(Mime[:turbo_stream])
      expect(user.reload.email_address).to eq(new_email)
    end

    it "sends a verification code when requesting an email change" do
      ActionMailer::Base.deliveries.clear
      new_email = "verify-email-#{user.id}@example.com"

      patch_settings_turbo(
        {
          ui_context: "profile",
          email_confirm: new_email,
          user: { email_address: new_email }
        }
      )

      expect(response).to have_http_status(:ok)
      expect(user.reload.email_address).not_to eq(new_email)
      expect(user.pending_email_address).to eq(new_email)
      expect(user.email_change_code_digest).to be_present
      expect(user.email_change_code_sent_at).to be_present
      expect(ActionMailer::Base.deliveries.last&.to).to include(new_email)
    end

    it "supports html request when requesting an email change code" do
      new_email = "verify-html-#{user.id}@example.com"

      patch_settings(
        {
        email_confirm: new_email,
        user: { email_address: new_email }
      }
      )

      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(settings_path)
      expect(user.reload.pending_email_address).to eq(new_email)
    end

    it "updates the email only after a valid verification code" do
      new_email = "verified-final-#{user.id}@example.com"
      user.store_email_change_request!(new_email: new_email, code: "123456")

      patch_settings_turbo(
        {
          ui_context: "profile",
          email_confirm: new_email,
          email_verification_code: "123456",
          user: { email_address: new_email }
        }
      )

      expect(response).to have_http_status(:ok)
      expect(user.reload.email_address).to eq(new_email)
      expect(user.pending_email_address).to be_nil
      expect(user.email_change_code_digest).to be_nil
      expect(user.email_change_code_sent_at).to be_nil
    end

    it "returns an error when verification code is invalid" do
      new_email = "invalid-code-#{user.id}@example.com"
      user.store_email_change_request!(new_email: new_email, code: "123456")

      patch_settings_turbo(
        {
          ui_context: "profile",
          email_confirm: new_email,
          email_verification_code: "000000",
          user: { email_address: new_email }
        }
      )

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.reload.email_address).not_to eq(new_email)
    end

    it "supports html request for invalid verification code" do
      new_email = "invalid-html-#{user.id}@example.com"
      user.store_email_change_request!(new_email: new_email, code: "123456")

      patch_settings(
        {
        email_confirm: new_email,
        email_verification_code: "000000",
        user: { email_address: new_email }
      }
      )

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.reload.email_address).not_to eq(new_email)
    end

    it "returns an error when verification code is expired" do
      new_email = "expired-code-#{user.id}@example.com"
      user.store_email_change_request!(new_email: new_email, code: "123456")
      user.update!(email_change_code_sent_at: 16.minutes.ago)

      patch_settings_turbo(
        {
          ui_context: "profile",
          email_confirm: new_email,
          email_verification_code: "123456",
          user: { email_address: new_email }
        }
      )

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.reload.email_address).not_to eq(new_email)
    end

    it "returns an error when pending email does not match requested email" do
      user.store_email_change_request!(new_email: "pending-#{user.id}@example.com", code: "123456")
      requested_email = "other-#{user.id}@example.com"

      patch_settings_turbo(
        {
          ui_context: "profile",
          email_confirm: requested_email,
          email_verification_code: "123456",
          user: { email_address: requested_email }
        }
      )

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.reload.email_address).not_to eq(requested_email)
    end

    it "returns an error when mailer fails while requesting code" do
      allow(UserMailer).to receive(:email_change_verification).and_raise(StandardError, "smtp down")
      new_email = "mailer-fail-#{user.id}@example.com"

      patch_settings_turbo(
        {
          ui_context: "profile",
          email_confirm: new_email,
          user: { email_address: new_email }
        }
      )

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.reload.pending_email_address).to eq(new_email)
    end

    it "does not alter newsletter subscription when only email is submitted (modal-style payload)" do
      person = user.person
      NewsletterSubscriber.where(email: person.email).delete_all
      subscriber = NewsletterSubscriber.create!(
        email: person.email,
        person: person,
        subscribed: true,
        source: "authenticated"
      )

      patch_settings_turbo(
        {
          ui_context: "profile",
          email_confirm: "confirm-field-present",
          user: { email_address: user.email_address }
        }
      )

      expect(response).to have_http_status(:unprocessable_content)
      expect(subscriber.reload.subscribed).to be(true)
    end
  end
end
