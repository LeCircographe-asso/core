# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  let(:person) { build(:person) }
  let(:user)   { build(:user, person: person) }

  describe "#welcome_email" do
    subject(:mail) { described_class.welcome_email(user) }

    it "est envoyé à l'utilisateur" do
      expect(mail.to).to eq([ user.email_address ])
    end

    it "a le bon sujet" do
      expect(mail.subject).to eq(I18n.t("mailers.user_mailer.welcome_email.subject"))
    end
  end

  describe "#welcome_by_admin" do
    subject(:mail) { described_class.welcome_by_admin(user, "https://example.com/reset") }

    it "est envoyé à l'utilisateur" do
      expect(mail.to).to eq([ user.email_address ])
    end

    it "a le bon sujet" do
      expect(mail.subject).to eq(I18n.t("mailers.user_mailer.welcome_by_admin.subject"))
    end

    it "inclut l'url de reset dans le corps" do
      expect(mail.body.decoded).to include("https://example.com/reset")
    end
  end

  describe "#email_change_verification" do
    subject(:mail) { described_class.email_change_verification(user, "new@example.com", "123456") }

    it "est envoyé à la nouvelle adresse" do
      expect(mail.to).to eq([ "new@example.com" ])
    end

    it "a le bon sujet" do
      expect(mail.subject).to eq(I18n.t("mailers.user_mailer.email_change_verification.subject"))
    end

    it "inclut le code de vérification dans le corps" do
      expect(mail.html_part.body.decoded).to include("123456")
    end
  end

  describe "#contact_email" do
    it "uses translated category label and exposes sender address to templates" do
      mail = described_class.contact_email("Ada", "ada@example.com", "Hello", "creative_hosting", "team@example.com")

      label = I18n.t("mailers.user_mailer.contact_email.category_labels.creative_hosting")
      expect(mail.subject).to eq(I18n.t("mailers.user_mailer.contact_email.subject", category_label: label))
      expect(mail.reply_to).to eq([ "ada@example.com" ])

      body = mail.html_part.body.decoded
      expect(body).to include(label)
      expect(body).to include("ada@example.com")
    end
  end

  describe "#membership_expiration_reminder" do
    it "est en attente de correction (membership.user et membership.end_date non définis)" do
      pending "mailer non branché — bugs membership.user / membership.end_date à corriger avant"
      raise "not implemented"
    end
  end
end
