# frozen_string_literal: true

class ContributionFormula < ApplicationRecord
  include RateKindable
  include Priceable
  include Humanizable
  include Versionable

  belongs_to :membership_type
  has_many :contributions, dependent: :destroy
  belongs_to :created_by_user, class_name: "User", optional: true

  validates :name, presence: true, uniqueness: { scope: :version }
  validates :duration, presence: true
  validates :price_cents, presence: true, numericality: { greater_than: 0 }
  validates :sessions_count, numericality: { greater_than: 0 }, if: :is_pack?
  validates :validity_days, numericality: { greater_than: 0 }, if: :is_pack?
  validates :version, presence: true, numericality: { greater_than: 0 }
  validates :effective_from, presence: true

  enum :duration, {
    day: 0,
    trimester: 1,
    annual: 2,
    pack10: 3
  }

  def for_circus_members?
    membership_type.circus?
  end

  def is_pack?
    duration == "pack10"
  end

  def is_pack10?
    duration == "pack10"
  end

  def is_annual?
    duration == "annual"
  end

  def is_trimester?
    duration == "trimester"
  end

  def is_day?
    duration == "day"
  end

  def duration_days
    case duration
    when "day"
      1
    when "trimester"
      90
    when "annual"
      365
    when "pack10"
      nil
    else
      0
    end
  end

  def sessions_available
    is_pack? ? sessions_count : nil
  end

  def create_price_change!(new_price_cents, effective_from: Date.current, reason: nil, user: nil)
    update!(effective_until: effective_from - 1.day)

    new_version = dup
    new_version.assign_attributes(
      version: version + 1,
      price_cents: new_price_cents,
      effective_from: effective_from,
      effective_until: nil,
      created_by_user: user,
      change_reason: reason
    )
    new_version.save!

    new_version
  end

  def price_evolution
    ContributionFormula.where(name: name).price_history
  end

  def price_change_percentage(from_date, to_date)
    old_price = ContributionFormula.where(name: name, effective_from: from_date).first&.price_cents
    new_price = ContributionFormula.where(name: name, effective_from: to_date).first&.price_cents

    return nil unless old_price && new_price && old_price.positive?

    ((new_price - old_price).to_f / old_price * 100).round(2)
  end

  scope :for_circus_members, -> { joins(:membership_type).where(membership_types: { category: :circus }) }
  scope :day_plans, -> { where(duration: :day) }
  scope :trimester_plans, -> { where(duration: :trimester) }
  scope :annual_plans, -> { where(duration: :annual) }
  scope :pack_plans, -> { where(duration: :pack10) }
  scope :by_price, -> { order(:price_cents) }
  scope :current_versions, -> { where(effective_until: nil) }
  scope :effective_on, ->(date) { where("effective_from <= ? AND (effective_until IS NULL OR effective_until >= ?)", date, date) }
  scope :price_history, -> { order(:effective_from, :version) }

  def self.available_for(person)
    return none unless person&.current_membership&.membership_type&.circus?

    for_circus_members
      .current_versions
      .for_rate_kinds(person.allowed_rate_kinds)
      .order(:duration, :price_cents)
  end

  def self.create_default_plans!
    circus_types = MembershipType.circus_types

    circus_types.each do |membership_type|
      find_or_create_by(name: "Journée - #{membership_type.name}", version: 1) do |sp|
        sp.membership_type = membership_type
        sp.duration = :day
        sp.rate_kind = membership_type.rate_kind
        sp.price_cents = 800
        sp.description = "Accès aux cours pour une journée"
        sp.version = 1
        sp.effective_from = Date.current
      end

      find_or_create_by(name: "Trimestre - #{membership_type.name}", version: 1) do |sp|
        sp.membership_type = membership_type
        sp.duration = :trimester
        sp.rate_kind = membership_type.rate_kind
        sp.price_cents = 6000
        sp.description = "Accès aux cours pendant 3 mois"
        sp.version = 1
        sp.effective_from = Date.current
      end

      find_or_create_by(name: "Annuel - #{membership_type.name}", version: 1) do |sp|
        sp.membership_type = membership_type
        sp.duration = :annual
        sp.rate_kind = membership_type.rate_kind
        sp.price_cents = 20_000
        sp.description = "Accès aux cours pendant 1 an"
        sp.version = 1
        sp.effective_from = Date.current
      end

      find_or_create_by(name: "Pack 10 séances - #{membership_type.name}", version: 1) do |sp|
        sp.membership_type = membership_type
        sp.duration = :pack10
        sp.rate_kind = membership_type.rate_kind
        sp.price_cents = 7000
        sp.sessions_count = 10
        sp.validity_days = 365
        sp.description = "10 séances valables 1 an"
        sp.version = 1
        sp.effective_from = Date.current
      end
    end
  end
end
