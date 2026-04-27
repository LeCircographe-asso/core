class PaymentLine < ApplicationRecord
  include Priceable

  # Relations
  belongs_to :payment
  belongs_to :item, polymorphic: true, optional: true

  # Validations
  validates :amount_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :item_type, presence: true
  validates :item_id, presence: true
  validates :payment_id, uniqueness: { scope: [ :item_type, :item_id ] }

  # Méthodes
  def item_description
    case item_type
    when "Membership"
      item&.membership_type&.name || "Adhésion"
    when "SubscriptionPlan"
      item&.duration_humanized || "Cotisation"
    when "MembershipType"
      item&.name || "Type d'adhésion"
    when "BookOfEntry"
      if item&.subscription_plan
        item.subscription_plan.duration_humanized
      else
        "Cotisation"
      end
    when "Donation"
      description.presence || "Donation"
    else
      item_type.humanize
    end
  end

  # (amount_euros maintenant dans le module Priceable)

  # Scopes
  scope :memberships, -> { where(item_type: "Membership") }
  scope :subscription_plans, -> { where(item_type: "SubscriptionPlan") }
  scope :membership_types, -> { where(item_type: "MembershipType") }
  scope :donations, -> { where(item_type: "Donation") }
  scope :by_item_type, ->(type) { where(item_type: type) }

  # Méthodes de classe pour créer des lignes de paiement
  def self.create_for_membership!(payment, membership, amount_cents)
    create!(
      payment: payment,
      item: membership,
      amount_cents: amount_cents,
      description: "Adhésion #{membership.membership_type.name}"
    )
  end

  def self.create_for_subscription_plan!(payment, subscription_plan, amount_cents)
    create!(
      payment: payment,
      item: subscription_plan,
      amount_cents: amount_cents,
      description: "#{subscription_plan.name} (#{subscription_plan.duration})"
    )
  end

  def self.create_for_membership_type!(payment, membership_type, amount_cents)
    create!(
      payment: payment,
      item: membership_type,
      amount_cents: amount_cents,
      description: "Adhésion #{membership_type.name}"
    )
  end
end
