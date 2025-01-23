class TrainingAttendee < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :training_session
  belongs_to :user_membership, optional: true
  belongs_to :recorded_by, class_name: 'User'

  # Validations
  validates :user_id, uniqueness: { 
    scope: [:training_session_id, :created_at],
    message: "déjà enregistré pour cette session" 
  }
  validate :user_can_train
  validate :session_not_full

  # Callbacks
  before_create :assign_membership
  after_create :decrement_entries_count, if: -> { user_membership&.booklet? }

  private

  def user_can_train
    unless training_session.can_add_attendee?(user)
      errors.add(:base, "L'utilisateur ne peut pas s'entraîner aujourd'hui")
    end
  end

  def session_not_full
    if training_session.full?
      errors.add(:base, "La session est complète")
    end
  end

  def assign_membership
    self.user_membership ||= user.current_subscription if user
  end

  def decrement_entries_count
    user_membership.decrement_entries! if user_membership.booklet?
  end
end 