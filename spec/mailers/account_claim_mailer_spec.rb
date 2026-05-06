# frozen_string_literal: true

require "rails_helper"

RSpec.describe AccountClaimMailer, type: :mailer do
  describe "#confirmation_email" do
    let(:person) { create(:person) }
    let(:user)   { create(:user, person: person) }
    let(:claim)  { create(:account_claim, :with_user, person: person) }

    subject(:mail) { described_class.confirmation_email(claim) }

    it "est envoyé à l'utilisateur du claim" do
      expect(mail.to).to eq([ claim.user.email_address ])
    end

    it "a le bon sujet" do
      expect(mail.subject).to eq(I18n.t("mailers.account_claim_mailer.confirmation_email.subject"))
    end

    it "inclut le token de confirmation dans le corps" do
      expect(mail.body.decoded).to include(claim.confirmation_token)
    end
  end
end
