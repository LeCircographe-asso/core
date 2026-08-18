# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Contacts", type: :request do
  describe "POST /submit_contact" do
    around do |example|
      previous = ENV.fetch("CONTACT_EMAIL_GENERAL", nil)
      ENV["CONTACT_EMAIL_GENERAL"] = "inbox@example.com"
      example.run
    ensure
      if previous
        ENV["CONTACT_EMAIL_GENERAL"] = previous
      else
        ENV.delete("CONTACT_EMAIL_GENERAL")
      end
    end

    it "does not require authentication" do
      expect do
        post submit_contact_path,
             params: {
               name: "Jane",
               email: "jane@example.com",
               category: "general",
               message: "Hello"
             },
             as: :turbo_stream
      end.to have_enqueued_mail(UserMailer, :contact_email)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("turbo-stream")
      expect(response.body).to include(I18n.t("contacts.create.success_title"))
    end

    it "redirects HTML format to the contact page" do
      post submit_contact_path, params: {
        name: "Jane",
        email: "jane@example.com",
        category: "general",
        message: "Hello"
      }

      expect(response).to redirect_to(contact_path)
    end

    it "rejects an invalid email format without enqueuing mail" do
      expect do
        post submit_contact_path,
             params: {
               name: "Jane",
               email: "not-an-email",
               category: "general",
               message: "Hello"
             },
             as: :turbo_stream
      end.not_to have_enqueued_mail(UserMailer, :contact_email)

      expect(response).to have_http_status(:success)
      expect(response.body).to include(I18n.t("contacts.create.invalid_email"))
    end

    it "rejects an empty payload without enqueuing mail" do
      expect do
        post submit_contact_path, params: {}, as: :turbo_stream
      end.not_to have_enqueued_mail(UserMailer, :contact_email)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("turbo-stream")
    end

    it "actually shows the error message to the visitor (flash frame updated, not just the form)" do
      post submit_contact_path, params: {}, as: :turbo_stream

      expect(response.body).to include(%(target="#{ProfileSectionDomIds::FLASH_FRAME}"))
      expect(response.body).to include(I18n.t("contacts.create.blank_fields"))
    end

    it "rejects a partial payload when required keys are omitted" do
      expect do
        post submit_contact_path,
             params: { name: "Jane", email: "jane@example.com" },
             as: :turbo_stream
      end.not_to have_enqueued_mail(UserMailer, :contact_email)

      expect(response).to have_http_status(:success)
    end

    context "when category is creative_hosting" do
      around do |example|
        prev_general = ENV.fetch("CONTACT_EMAIL_GENERAL", nil)
        prev_hosting = ENV.fetch("CONTACT_EMAIL_CREATIVE_HOSTING", nil)
        prev_residence = ENV.fetch("CONTACT_EMAIL_RESIDENCE", nil)
        ENV["CONTACT_EMAIL_GENERAL"] = "general@example.com"
        ENV["CONTACT_EMAIL_CREATIVE_HOSTING"] = "hosting@example.com"
        ENV.delete("CONTACT_EMAIL_RESIDENCE")
        example.run
      ensure
        prev_general ? ENV["CONTACT_EMAIL_GENERAL"] = prev_general : ENV.delete("CONTACT_EMAIL_GENERAL")
        prev_hosting ? ENV["CONTACT_EMAIL_CREATIVE_HOSTING"] = prev_hosting : ENV.delete("CONTACT_EMAIL_CREATIVE_HOSTING")
        prev_residence ? ENV["CONTACT_EMAIL_RESIDENCE"] = prev_residence : ENV.delete("CONTACT_EMAIL_RESIDENCE")
      end

      it "enqueues contact mail" do
        expect do
          post submit_contact_path,
               params: {
                 name: "Jane",
                 email: "jane@example.com",
                 category: "creative_hosting",
                 message: "Projet"
               },
               as: :turbo_stream
        end.to have_enqueued_mail(UserMailer, :contact_email)

        expect(response).to have_http_status(:success)
      end
    end

    context "when the category-specific email is not configured" do
      around do |example|
        prev_general = ENV.fetch("CONTACT_EMAIL_GENERAL", nil)
        prev_technical = ENV.fetch("CONTACT_EMAIL_TECHNICAL", nil)
        ENV["CONTACT_EMAIL_GENERAL"] = "general@example.com"
        ENV.delete("CONTACT_EMAIL_TECHNICAL")
        example.run
      ensure
        prev_general ? ENV["CONTACT_EMAIL_GENERAL"] = prev_general : ENV.delete("CONTACT_EMAIL_GENERAL")
        prev_technical ? ENV["CONTACT_EMAIL_TECHNICAL"] = prev_technical : ENV.delete("CONTACT_EMAIL_TECHNICAL")
      end

      it "falls back to the general inbox instead of losing the message" do
        expect do
          post submit_contact_path,
               params: {
                 name: "Jane",
                 email: "jane@example.com",
                 category: "technical",
                 message: "Bug sur le site"
               },
               as: :turbo_stream
        end.to have_enqueued_mail(UserMailer, :contact_email).with("Jane", "jane@example.com", "Bug sur le site", "technical", "general@example.com")

        expect(response).to have_http_status(:success)
      end
    end

    context "when no recipient email is configured at all" do
      around do |example|
        prev_general = ENV.fetch("CONTACT_EMAIL_GENERAL", nil)
        ENV.delete("CONTACT_EMAIL_GENERAL")
        example.run
      ensure
        prev_general ? ENV["CONTACT_EMAIL_GENERAL"] = prev_general : ENV.delete("CONTACT_EMAIL_GENERAL")
      end

      it "shows an error instead of silently enqueuing a mail with no recipient" do
        expect do
          post submit_contact_path,
               params: {
                 name: "Jane",
                 email: "jane@example.com",
                 category: "general",
                 message: "Hello"
               },
               as: :turbo_stream
        end.not_to have_enqueued_mail(UserMailer, :contact_email)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("erreur est survenue")
      end
    end

    context "when category is legacy residence" do
      around do |example|
        prev_general = ENV.fetch("CONTACT_EMAIL_GENERAL", nil)
        prev_hosting = ENV.fetch("CONTACT_EMAIL_CREATIVE_HOSTING", nil)
        prev_residence = ENV.fetch("CONTACT_EMAIL_RESIDENCE", nil)
        ENV["CONTACT_EMAIL_GENERAL"] = "general@example.com"
        ENV.delete("CONTACT_EMAIL_CREATIVE_HOSTING")
        ENV["CONTACT_EMAIL_RESIDENCE"] = "legacy-hosting@example.com"
        example.run
      ensure
        prev_general ? ENV["CONTACT_EMAIL_GENERAL"] = prev_general : ENV.delete("CONTACT_EMAIL_GENERAL")
        prev_hosting ? ENV["CONTACT_EMAIL_CREATIVE_HOSTING"] = prev_hosting : ENV.delete("CONTACT_EMAIL_CREATIVE_HOSTING")
        prev_residence ? ENV["CONTACT_EMAIL_RESIDENCE"] = prev_residence : ENV.delete("CONTACT_EMAIL_RESIDENCE")
      end

      it "still enqueues contact mail (normalized to creative_hosting routing)" do
        expect do
          post submit_contact_path,
               params: {
                 name: "Jane",
                 email: "jane@example.com",
                 category: "residence",
                 message: "Projet"
               },
               as: :turbo_stream
        end.to have_enqueued_mail(UserMailer, :contact_email)

        expect(response).to have_http_status(:success)
      end
    end
  end
end
