class TrainingSession < ApplicationRecord
  # Associations
  belongs_to :recorded_by, class_name: 'User'
  has_many :training_attendees, dependent: :destroy
  has_many :users, through: :training_attendees

  # Validations
  validates :date, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[open closed cancelled] }
  validates :max_capacity, numericality: { greater_than: 0 }

  # Scopes
  scope :today, -> { where(date: Date.current) }
  scope :open, -> { where(status: 'open') }
  scope :upcoming, -> { where('date >= ?', Date.current).order(:date) }

  # Class methods
  def self.current_or_create(recorded_by:)
    today.first_or_create!(
      date: Date.current,
      recorded_by: recorded_by,
      status: 'open'
    )
  end

  def self.create_for_today
    # Fermer la session d'hier si elle existe
    yesterday = Date.yesterday
    if (old_session = find_by(date: yesterday))
      old_session.update(status: 'closed')
    end

    # Créer la nouvelle session
    create!(
      date: Date.current,
      status: 'open',
      recorded_by: User.find_by(role: 'admin')
    )
  end

  # Instance methods
  def full?
    training_attendees.count >= max_capacity
  end

  def add_attendee!(user, recorded_by: nil)
    training_attendees.create!(
      user: user,
      recorded_by: recorded_by || self.recorded_by,
      user_membership: user.current_subscription
    )
  end

  def can_add_attendee?(user)
    return false if full?
    return false if user.already_trained_today?
    user.can_train_today?
  end
end 