# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  describe "#contact_email" do
    it "uses translated category label and exposes sender address to templates" do
      mail = described_class.contact_email("Ada", "ada@example.com", "Hello", "creative_hosting", "team@example.com")

      label = I18n.t("mailers.user_mailer.contact_email.category_labels.creative_hosting")
      expect(mail.subject).to eq(I18n.t("mailers.user_mailer.contact_email.subject", category_label: label))
      expect(mail.reply_to).to eq(["ada@example.com"])

      body = mail.html_part.body.decoded
      expect(body).to include(label)
      expect(body).to include("ada@example.com")
    end
  end
end
