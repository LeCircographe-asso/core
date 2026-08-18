# frozen_string_literal: true

require "prawn"

module People
  # Génère le PDF d'un +DonationReceipt+ à la volée à partir des métadonnées
  # déjà figées en base (numéro, émetteur, donateur — voir DonationReceiptIssuer).
  # Volontairement jamais persisté : ni ActiveStorage, ni fichier sur disque,
  # le PDF est reconstruit à chaque téléchargement/envoi. Coût de stockage nul.
  #
  # N'établit aucune éligibilité fiscale (pas de mention art. 200/238 bis CGI) :
  # l'association n'a pas encore confirmé son agrément intérêt général, un
  # reçu mentionnant une réduction d'impôt sans base légale est sanctionné
  # (art. 1740 A du CGI). Disclaimer explicite en pied de page tant que ce
  # n'est pas tranché.
  class DonationReceiptGenerator
    include ActiveModel::Model

    # Police AFM intégrée : couvre le Latin-1 (accents français) via WinAnsiEncoding,
    # l'avertissement Prawn concerne l'UTF-8 complet (non nécessaire ici).
    Prawn::Fonts::AFM.hide_m17n_warning = true

    attr_accessor :donation_receipt

    validates :donation_receipt, presence: true

    def call
      raise ArgumentError, errors.full_messages.join(", ") unless valid?

      build_pdf.render
    end

    private

    def build_pdf
      Prawn::Document.new(page_size: "A4", margin: 56) do |pdf|
        pdf.text "Reçu de don", size: 20, style: :bold
        pdf.move_down 4
        pdf.text "N° #{donation_receipt.number}", size: 10, color: "666666"
        pdf.move_down 20

        pdf.text donation_receipt.issuer, style: :bold
        pdf.text donation_receipt.issuer_address if donation_receipt.issuer_address.present?
        pdf.move_down 20

        pdf.text "Émis le #{I18n.l(donation_receipt.issued_at.to_date)}"
        pdf.move_down 20

        pdf.text "Reçu de :", style: :bold
        pdf.text donation_receipt.donor_name
        pdf.text donation_receipt.donor_address if donation_receipt.donor_address.present?
        pdf.move_down 20

        pdf.text "Nous certifions avoir reçu de #{donation_receipt.donor_name} un don d'un montant de " \
                  "#{amount_formatted}, versé le #{I18n.l(payment.created_at.to_date)} par " \
                  "#{payment.payment_method_humanized.downcase}.",
                  align: :justify
        pdf.move_down 40

        pdf.text "Ce document atteste la réception du don. Il ne constitue pas, à ce jour, un justificatif " \
                  "ouvrant droit à réduction d'impôt.",
                  size: 8, color: "999999", style: :italic
      end
    end

    def payment_line
      donation_receipt.payment_line
    end

    def payment
      payment_line.payment
    end

    def amount_formatted
      ActiveSupport::NumberHelper.number_to_currency(
        payment_line.price_euros, unit: "€", format: "%n %u", precision: 2, locale: :fr
      )
    end
  end
end
