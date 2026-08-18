# frozen_string_literal: true

module Admin
  # PDF jamais stocké : régénéré à chaque #show/#resend depuis les métadonnées
  # de DonationReceipt (voir People::DonationReceiptGenerator).
  class DonationReceiptsController < BaseController
    def show
      payment = find_payment
      receipt = find_donation_line(payment)&.donation_receipt
      return redirect_to_payments(payment, alert: t(".missing")) if receipt.blank?

      pdf = People::DonationReceiptGenerator.new(donation_receipt: receipt).call
      send_data pdf, filename: "recu-don-#{receipt.number}.pdf", type: "application/pdf", disposition: "inline"
    end

    def create
      payment = find_payment
      donation_line = find_donation_line(payment)
      return redirect_to_payments(payment, alert: t(".not_a_donation")) if donation_line.blank?

      result = People::DonationReceiptIssuer.new(payment_line: donation_line).call

      if result.success?
        redirect_to_payments(payment, notice: t(".issued"))
      else
        redirect_to_payments(payment, alert: result.message)
      end
    end

    def resend
      payment = find_payment
      receipt = find_donation_line(payment)&.donation_receipt
      return redirect_to_payments(payment, alert: t(".missing")) if receipt.blank?

      DonationMailer.receipt_email(receipt).deliver_later
      redirect_to_payments(payment, notice: t(".resent"))
    end

    private

    def find_payment
      Payment.find(params[:payment_id])
    end

    def find_donation_line(payment)
      payment.payment_lines.find_by(item_type: "Donation")
    end

    def redirect_to_payments(payment, **flash_options)
      redirect_to admin_payments_path(person_id: payment.person_id, anchor: "payment_row_#{payment.id}"), **flash_options
    end
  end
end
