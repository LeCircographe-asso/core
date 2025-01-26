class UserMembership < ApplicationRecord
  belongs_to :user
  belongs_to :subscription_type
  belongs_to :payment, optional: true

  # has_many :payments, dependent: :destroy
  has_many :training_attendees
  has_many :user_membership_subscriptions
  has_many :subscription_types, through: :user_membership_subscriptions

  # Validations
  validates :user_id, :subscription_type_id, presence: true
  validates :start_date, :end_date, presence: true
  validates :status, presence: true
  validate :end_date_after_start_date
  validate :one_active_membership_per_type

  enum status: {
    pending: 'pending',
    active: 'active',
    expired: 'expired',
    cancelled: 'cancelled',
    suspended: 'suspended'
  }

  # Scopes utiles
  scope :active, -> { where(status: 'active').where('end_date > ?', Date.current) }
  scope :expired, -> { where(status: 'active').where('end_date <= ?', Date.current) }
  scope :by_type, ->(category) { joins(:subscription_type).where(subscription_types: { category: category }) }
  scope :with_remaining_sessions, -> { where('remaining_sessions > 0') }

  private

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?

    if end_date < start_date
      errors.add(:end_date, "doit être après la date de début")
    end
  end

  def one_active_membership_per_type
    return unless active?
    
    existing = UserMembership.active
                           .by_type(subscription_type.category)
                           .where(user_id: user_id)
                           .where.not(id: id)
                           .exists?

    if existing
      errors.add(:base, "Un abonnement actif de ce type existe déjà")
    end
  end
end
