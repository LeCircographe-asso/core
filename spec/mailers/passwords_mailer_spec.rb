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
end
