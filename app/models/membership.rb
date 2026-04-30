# frozen_string_literal: true

class Membership < ApplicationRecord
  include Statusable
  include Dateable

  # Relations — voir docs/domain_model.md.
  belongs_to :person
  belongs_to :membership_type
  # Validations
  validates :started_at, presence: true
  validates :ended_at, presence: true
  validates :status, presence: true

  # Statuts — voir docs/glossary.md.
  enum :status, {
    pending: 0,
    inactive: 1,
    active: 2,
    expired: 3
  }

  # Validations personnalisées
  validate :end_date_after_start_date
  validate :no_overlapping_active_memberships, on: :create, unless: :skip_overlap_validation

  # Attribut pour skip validation dans certains cas (upgrades, tests)
  attr_accessor :skip_overlap_validation

  # Status methods from Statusable module
  # expired? checks status == "expired"
  # expired_by_date? checks if ended_at is in the past

  def expired_by_date?
    Date.current > ended_at
  end

  def can_upgrade_to?(membership_type)
    # Un membre Basic peut passer à Circus
    # Un membre Circus peut changer de type Circus
    return false if membership_type == self.membership_type
    return true if basic? && membership_type.circus?
    return true if circus? && membership_type.circus?

    false
  end

  def basic?
    membership_type&.basic?
  end

  def circus?
    membership_type&.circus?
  end

  def upgrade_to!(new_membership_type, started_at = Date.current)
    # Vérifier qu'on peut faire l'upgrade
    raise "Cannot upgrade to this membership type" unless can_upgrade_to?(new_membership_type)

    # Préserver la date de première adhésion
    first_joined = first_joined_at || started_at

    # Perform upgrade in transaction for atomicity
    transaction do
      # 1. Mark current membership as inactive FIRST
      update!(status: :inactive)

      # 2. Create new membership (won't overlap since old one is now inactive)
      new_membership = person.memberships.create!(
        membership_type: new_membership_type,
        started_at: started_at,
        ended_at: started_at + 1.year,
        status: :active,
        first_joined_at: first_joined
      )

      new_membership
    end
  end

  # Scopes
  scope :current, -> { where("started_at <= ? AND ended_at >= ?", Date.current, Date.current) }
  scope :active, -> { where(status: :active) }
  scope :expired, -> { where(status: :expired) }
  scope :expired_by_date, -> { where(ended_at: ...Date.current) }
  scope :inactive, -> { where(status: :inactive) }
  scope :basic, -> { joins(:membership_type).where(membership_types: { category: :basic }) }
  scope :circus, -> { joins(:membership_type).where(membership_types: { category: :circus }) }

  private

  def end_date_after_start_date
    return unless started_at && ended_at

    errors.add(:ended_at, "must be after start date") if ended_at <= started_at
  end

  def no_overlapping_active_memberships
    return unless person && started_at && ended_at

    overlapping = person.memberships.active.where.not(id: id)
                        .where("started_at <= ? AND ended_at >= ?", ended_at, started_at)

    errors.add(:base, "Person already has an active membership during this period") if overlapping.exists?
  end
end
