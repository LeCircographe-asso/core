# frozen_string_literal: true

# Métadonnées du reçu fiscal émis pour un don (voir docs/payments.md §4).
# Une PaymentLine de don (item_type: "Donation") porte au plus un reçu ;
# le numéro est séquentiel par année civile (format "AAAA-NNN") et
# l'émetteur est figé au moment de l'émission pour rester une preuve stable
# même si l'identité légale de l'association change ensuite.
class DonationReceipt < ApplicationRecord
  belongs_to :payment_line

  validates :number, :issued_at, :issuer, presence: true
  validates :number, uniqueness: true
  validate :payment_line_is_a_donation

  private

  def payment_line_is_a_donation
    return if payment_line.blank? || payment_line.item_type == "Donation"

    errors.add(:payment_line, "doit correspondre à une ligne de don (item_type: Donation)")
  end
end
