# frozen_string_literal: true

require "rails_helper"

RSpec.describe DonationMailer, type: :mailer do
  describe "#receipt_email" do
    let(:payment) { create(:payment, status: :success) }
    let!(:donation_line) do
      create(:payment_line, payment: payment, item_type: "Donation", item_id: payment.id, amount_cents: 1000, description: "Don libre")
    end
    let(:receipt) do
      People::DonationReceiptIssuer.new(payment_line: donation_line).call
      donation_line.reload.donation_receipt
    end

    # Régression : la vue utilisait t(".title") (→ donation_mailer.receipt_email.*) alors que
    # les clés vivent sous mailers.donation_mailer.* — le rendu levait, le reçu ne partait jamais.
    it "rend le corps traduit et joint le PDF" do
      mail = described_class.receipt_email(receipt)

      expect(mail.to).to eq([ payment.person.email ])
      expect(mail.body.parts.find { |part| part.content_type.start_with?("text/html") }.decoded)
        .to include(I18n.t("mailers.donation_mailer.receipt_email.title"))
      expect(mail.attachments.map(&:filename)).to eq([ "recu-don-#{receipt.number}.pdf" ])
    end
  end
end
