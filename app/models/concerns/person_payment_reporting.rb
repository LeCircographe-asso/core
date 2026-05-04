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

  def offered_payments_count
    payments.where(payment_method: "offered").count
  end

  def offered_payments_total
    payments.where(payment_method: "offered").sum(:total_cents)
  end

  def free_offers_count
    payments.where(payment_method: "offered", total_cents: 0).count
  end

  def paid_offers_count
    payments.where(payment_method: "offered").where("total_cents > 0").count
  end

  def membership_upgrades_count
    payments.joins(:payment_lines)
            .where(payment_lines: { item_type: "MembershipUpgrade" })
            .count
  end

  def contribution_purchases_count
    payments.joins(:payment_lines)
            .where(payment_lines: { item_type: "Contribution" })
            .count
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
