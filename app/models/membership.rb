class Membership < ApplicationRecord
  # Relations selon le domain_model_circographe.md
  belongs_to :person
  belongs_to :membership_type

  # Anciennes relations désactivées (à supprimer progressivement)
  # has_many :user_memberships, dependent: :destroy
  # has_many :users, through: :user_memberships

  # Validations
  validates :started_at, presence: true
  validates :ended_at, presence: true
  validates :status, presence: true

  # Enum pour les statuts selon le domain_model_circographe.md
  enum :status, {
    inactive: 0,
    active: 1,
    expired: 2
  }

  # Validations personnalisées
  validate :end_date_after_start_date
  validate :no_overlapping_active_memberships, on: :create

  # Méthodes
  def expired?
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

    # Créer la nouvelle adhésion
    new_membership = person.memberships.create!(
      membership_type: new_membership_type,
      started_at: started_at,
      ended_at: started_at + 1.year,
      status: :active,
      first_joined_at: first_joined
    )

    # Marquer l'ancienne comme inactive
    update!(status: :inactive)

    new_membership
  end

  # Scopes
  scope :current, -> { where("started_at <= ? AND ended_at >= ?", Date.current, Date.current) }
  scope :active, -> { where(status: :active) }
  scope :expired, -> { where(status: :expired) }
  scope :inactive, -> { where(status: :inactive) }
  scope :basic, -> { joins(:membership_type).where(membership_types: { category: :basic }) }
  scope :circus, -> { joins(:membership_type).where(membership_types: { category: [ :circus_full, :circus_reduced ] }) }

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
