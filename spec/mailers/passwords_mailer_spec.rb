# frozen_string_literal: true

require "rails_helper"

RSpec.describe PasswordsMailer, type: :mailer do
  let(:person) { build(:person) }
  let(:user)   { build(:user, person: person) }

  describe "#reset" do
    subject(:mail) { described_class.reset(user) }

    it "est envoyé à l'utilisateur" do
      expect(mail.to).to eq([ user.email_address ])
    end

    it "a le bon sujet" do
      expect(mail.subject).to eq(I18n.t("mailers.passwords_mailer.reset.subject"))
    end
  end

  describe "#changed" do
    subject(:mail) { described_class.changed(user) }

    # Régression : la clé FR manquait, le job levait I18n::MissingTranslationData
    # et l'alerte de sécurité ne partait jamais.
    it "a un sujet traduit dans chaque langue" do
      I18n.available_locales.each do |locale|
        I18n.with_locale(locale) do
          expect(described_class.changed(user).subject).to eq(I18n.t("mailers.passwords_mailer.changed.subject", raise: true))
        end
      end
    end

    it "est envoyé à l'utilisateur" do
      expect(mail.to).to eq([ user.email_address ])
    end
  end
end
