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

      expect(response).to redirect_to(page_path("contact_us"))
    end
  end
end
