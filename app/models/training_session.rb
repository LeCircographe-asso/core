class TrainingSession < ApplicationRecord
  belongs_to :recorded_by, class_name: 'User'
  has_many :training_attendees
  has_many :users, through: :training_attendees

  scope :today, -> { where(session_date: Date.today) }
  
  def self.current_or_create(recorded_by:)
    today.first_or_create!(
      session_date: Date.today,
      recorded_by: recorded_by
    )
  end

  def add_attendee!(user)
    return false unless user.can_train_today?
    
    transaction do
      attendance = training_attendees.create!(
        user: user,
        user_membership: user.current_subscription,
        recorded_by: recorded_by
      )

      # Mettre à jour le compteur pour les carnets
      if user.current_subscription.subscription_type.name == 'booklet'
        user.current_subscription.decrement_entries!
      end
      
      attendance
    end
  end
end 