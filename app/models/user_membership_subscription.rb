class UserMembershipSubscription < ApplicationRecord
  belongs_to :user_membership
  belongs_to :subscription_type

  validates :start_date, :end_date, presence: true
  validate :end_date_after_start_date
  validates :subscription_priority, presence: true

  enum status: {
    pending: 'pending',
    active: 'active',
    expired: 'expired',
    cancelled: 'cancelled',
    suspended: 'suspended'
  }

  # Priorités de souscription
  enum subscription_priority: {
    day: 0,
    pack: 1,
    trimester: 2,
    year: 3
  }

  # Scope pour les souscriptions disponibles
  scope :available, -> { where(status: 'active').where('end_date > ? OR end_date IS NULL', Time.current) }
  scope :with_remaining_sessions, -> { where('remaining_sessions > 0') }

  private

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?

    if end_date < start_date
      errors.add(:end_date, "doit être après la date de début")
    end
  end
end
