# frozen_string_literal: true

class DonationMailer < ApplicationMailer
  def receipt_email(donation_receipt)
    @donation_receipt = donation_receipt
    @payment = donation_receipt.payment_line.payment
    recipient = @payment.person.email

    return if recipient.blank?

    attachments["recu-don-#{donation_receipt.number}.pdf"] = People::DonationReceiptGenerator.new(donation_receipt: donation_receipt).call

    mail(
      to: recipient,
      subject: I18n.t("mailers.donation_mailer.receipt_email.subject", number: donation_receipt.number)
    )
  end
end
