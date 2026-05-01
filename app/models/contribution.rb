# frozen_string_literal: true

class Contribution < ApplicationRecord
  include Statusable
  include Dateable

  belongs_to :person
  belongs_to :contribution_formula

  validates :sessions_remaining, presence: true, numericality: { greater_than_or_equal_to: 0 }, if: :has_session_limit?
  validates :status, presence: true
  validates :purchased_at, presence: true
  validates :expires_at, presence: true, unless: :is_pack10?

  validate :sessions_remaining_validation
  validate :day_pass_single_use_validation
  validate :day_pass_expiration_validation

  enum :status, {
    inactive: 0,
    active: 1,
    expired: 2,
    consumed: 3,
    suspended: 4
  }

  before_create :set_initial_values

  def can_use?
    return false unless active?

    return false if has_session_limit? && !(sessions_remaining.present? && sessions_remaining.positive?)

    return false if expired? && !is_pack10?

    return false unless person.current_membership&.membership_type&.circus?

    true
  end

  def use_session!
    return false unless can_use?

    if has_session_limit?
      self.sessions_remaining -= 1

      self.status = :consumed if sessions_remaining.zero?
    end

    save!
  end

  def refund_session!
    return true unless has_session_limit?

    max_sessions = contribution_formula.sessions_count
    max_sessions ||= is_pack10? ? 10 : 1

    self.sessions_remaining ||= 0
    self.sessions_remaining = [ sessions_remaining + 1, max_sessions ].min
    self.status = :active if sessions_remaining.positive?
    save!
  end

  def expired?
    return false if is_pack10?

    return Time.current > expires_at.end_of_day if contribution_formula.duration == "day"

    Date.current > expires_at
  end

  def is_pack10?
    contribution_formula.duration == "pack10"
  end

  def has_session_limit?
    is_pack10? || contribution_formula.duration == "day"
  end

  def remaining_entries
    sessions_remaining
  end

  scope :expired_by_date, -> { where(expires_at: ...Date.current) }
  scope :not_expired_by_date, -> { where("expires_at IS NULL OR expires_at > ?", Date.current) }
  scope :with_expiration, -> { where.not(expires_at: nil) }
  scope :without_expiration, -> { where(expires_at: nil) }

  scope :active, -> { where(status: :active) }
  scope :expired, -> { where(status: :expired) }
  scope :consumed, -> { where(status: :consumed) }
  scope :suspended, -> { where(status: :suspended) }

  scope :usable, lambda {
    active
      .where("expires_at IS NULL OR expires_at > ?", Date.current)
      .where("sessions_remaining IS NULL OR sessions_remaining > 0")
  }

  def self.reactivate_suspended_packs_for_person(person)
    return unless person.can_buy_contribution_formulas?

    active_plans = person.contributions.active.joins(:contribution_formula).where.not(contribution_formulas: { duration: "pack10" })

    return unless active_plans.empty?

    person.contributions.suspended.joins(:contribution_formula).where(contribution_formulas: { duration: "pack10" }).find_each(&:reactivate!)
  end

  def suspend!(reason:)
    update!(status: :suspended, suspended_at: Time.current, suspended_reason: reason)
  end

  def reactivate!
    update!(status: :active, suspended_at: nil, suspended_reason: nil) if suspended?
  end

  def suspended?
    status == "suspended"
  end

  private

  def sessions_remaining_validation
    if contribution_formula&.duration.in?(%w[trimester annual])
      errors.add(:sessions_remaining, "doit être vide pour les cotisations illimitées") if sessions_remaining.present?
    elsif has_session_limit?
      errors.add(:sessions_remaining, "doit être présent et positif pour les Pack 10 et les Journées") if sessions_remaining.blank? || sessions_remaining.negative?
    end
  end

  def day_pass_single_use_validation
    return unless contribution_formula&.duration == "day"
    return if sessions_remaining.in?([ 0, 1 ])

    errors.add(:sessions_remaining, "doit être 1 avant utilisation puis 0 après utilisation pour une cotisation journée")
  end

  def day_pass_expiration_validation
    return unless contribution_formula&.duration == "day"
    return if expires_at.blank? || purchased_at.blank?

    expected_expiration = purchased_at.end_of_day
    return if expires_at.to_i == expected_expiration.to_i

    errors.add(:expires_at, "doit être la fin du jour d'achat pour une cotisation journée")
  end

  def set_initial_values
    self.purchased_at ||= Time.current
    self.status ||= :active
  end
end
