# frozen_string_literal: true

class PaymentLine < ApplicationRecord
  include Priceable

  ALLOWED_ITEM_TYPES = %w[
    Membership
    MembershipType
    MembershipUpgrade
    ContributionFormula
    Contribution
    Donation
  ].freeze

  belongs_to :payment
  belongs_to :item, polymorphic: true, optional: true

  validates :amount_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :item_type, presence: true, inclusion: { in: ALLOWED_ITEM_TYPES, message: :not_allowed }
  validates :item_id, presence: true
  validates :payment_id, uniqueness: { scope: %i[item_type item_id] }

  # Méthodes
  def item_description
    case item_type
    when "Membership"
      item&.membership_type&.name || I18n.t("payment_line.item_description.membership_fallback")
    when "MembershipType"
      item&.name || I18n.t("payment_line.item_description.membership_type_fallback")
    when "Contribution"
      if item&.contribution_formula
        item.contribution_formula.duration_humanized
      else
        I18n.t("payment_line.item_description.contribution_fallback")
      end
    when "ContributionFormula"
      item&.duration_humanized || I18n.t("payment_line.item_description.contribution_fallback")
    when "Donation"
      description.presence || I18n.t("payment_line.item_description.donation_fallback")
    else
      item_type.humanize
    end
  end

  # (amount_euros maintenant dans le module Priceable)

  # Scopes
  scope :memberships, -> { where(item_type: "Membership") }
  scope :contributions, -> { where(item_type: "Contribution") }
  scope :contribution_formulas, -> { where(item_type: "ContributionFormula") }
  scope :membership_types, -> { where(item_type: "MembershipType") }
  scope :donations, -> { where(item_type: "Donation") }
  scope :by_item_type, ->(type) { where(item_type: type) }

  # Méthodes de classe pour créer des lignes de paiement
  def self.create_for_membership!(payment, membership, amount_cents)
    create!(
      payment: payment,
      item: membership,
      amount_cents: amount_cents,
      description: I18n.t("payment_line.descriptions.membership", name: membership.membership_type.name)
    )
  end

  def self.create_for_contribution_formula!(payment, contribution_formula, amount_cents)
    create!(
      payment: payment,
      item: contribution_formula,
      amount_cents: amount_cents,
      description: I18n.t("payment_line.descriptions.contribution_formula",
                          name: contribution_formula.name,
                          duration: contribution_formula.duration)
    )
  end

  def self.create_for_membership_type!(payment, membership_type, amount_cents)
    create!(
      payment: payment,
      item: membership_type,
      amount_cents: amount_cents,
      description: I18n.t("payment_line.descriptions.membership_type", name: membership_type.name)
    )
  end
end
