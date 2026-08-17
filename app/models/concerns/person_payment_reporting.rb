# frozen_string_literal: true

module PersonPaymentReporting
  extend ActiveSupport::Concern

  class_methods do
    def total_offered_payments
      joins(:payments).where(payments: { payment_method: "offered" }).count
    end

    def total_free_offers
      joins(:payments).where(payments: { payment_method: "offered", total_cents: 0 }).count
    end

    def total_paid_offers
      joins(:payments).where(payments: { payment_method: "offered" }).where("payments.total_cents > 0").count
    end

    def offered_payments_by_reason
      joins(:payments)
        .where(payments: { payment_method: "offered" })
        .group("payments.offer_reason")
        .count
    end

    def upgrades_today
      joins(:payments)
        .joins("JOIN payment_lines ON payments.id = payment_lines.payment_id")
        .where(payment_lines: { item_type: "MembershipUpgrade" })
        .where(payments: { created_at: Date.current.all_day })
        .count
    end
  end

  # NOTE : ces compteurs/totaux s'appuient sur payment_lines.person_id (bénéficiaire),
  # pas sur payments.person_id (payeur), car un paiement multi-bénéficiaires peut
  # couvrir la cotisation d'une autre personne que le payeur. `payments` (payeur
  # uniquement) reste utilisé pour membership_upgrades_count, hors périmètre v1.

  def offered_payments_count
    Payment.where(payment_method: "offered", id: payment_lines_for_person.select(:payment_id)).count
  end

  def offered_payments_total
    # Somme des lignes qui bénéficient à CETTE personne, pas payment.total_cents
    # (qui inclurait les lignes des autres bénéficiaires du même paiement).
    offered_lines_for_person.sum(:amount_cents)
  end

  def free_offers_count
    offered_lines_for_person.where(amount_cents: 0).count
  end

  def paid_offers_count
    offered_lines_for_person.where("payment_lines.amount_cents > 0").count
  end

  def offered_lines_for_person
    payment_lines_for_person.joins(:payment).where(payments: { payment_method: "offered" })
  end

  def membership_upgrades_count
    payments.joins(:payment_lines)
            .where(payment_lines: { item_type: "MembershipUpgrade" })
            .count
  end

  def contribution_purchases_count
    payment_lines_for_person.where(item_type: "Contribution").count
  end

  def payment_lines_for_person
    PaymentLine.where(person_id: id)
  end

  def newsletter_subscribed?
    return false if email.blank?

    subscriber = NewsletterSubscriber.find_by(email: email)
    subscriber&.subscribed? || false
  end

  def newsletter_subscribed
    newsletter_subscribed?
  end

  def newsletter_subscribed=(_value)
    # Compatibility writer for legacy forms/factories. Newsletter persistence is handled by NewsletterSubscriber.
  end
end
