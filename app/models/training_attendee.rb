class TrainingAttendee < ApplicationRecord
  belongs_to :user
  belongs_to :user_membership
  belongs_to :checked_by, class_name: 'User'

  # Validations de base
  validates :user_id, :user_membership_id, :checked_by_id, :check_in_time, presence: true
  validates :user_id, uniqueness: { 
    scope: [:check_in_time], 
    message: "est déjà enregistré pour cette séance" 
  }
  
  # Attributs
  attribute :is_visitor, :boolean, default: false
  
  # Validations métier
  validate :user_has_valid_membership
  validate :validate_practice_requirements
  validate :user_has_remaining_sessions, if: -> { !is_visitor && user_membership&.subscription_type&.has_limited_sessions? }
  validate :validate_no_active_subscription_with_day_pass, if: -> { !is_visitor }
  
  # Callbacks
  after_create :decrement_sessions, if: -> { !is_visitor && user_membership&.subscription_type&.has_limited_sessions? }
  
  # Scopes utiles
  scope :today, -> { where(check_in_time: Time.current.beginning_of_day..Time.current.end_of_day) }
  scope :by_date, ->(date) { where(check_in_time: date.beginning_of_day..date.end_of_day) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :by_period, ->(start_date, end_date) { where(check_in_time: start_date..end_date) }
  scope :recorded_by_admin, -> { joins(:checked_by).where(users: { role: 'admin' }) }
  scope :visitors, -> { where(is_visitor: true) }
  scope :practitioners, -> { where(is_visitor: false) }
  
  private
  
  def user_has_valid_membership
    unless user_membership&.active?
      errors.add(:base, "L'utilisateur n'a pas d'adhésion valide")
    end
  end

  def validate_practice_requirements
    return if is_visitor # Les visiteurs n'ont pas besoin de validation supplémentaire
    
    # Vérifie l'adhésion cirque pour les pratiquants
    unless user.user_memberships.active.joins(:subscription_type)
                .where(subscription_types: { category: 'circus_membership' }).exists?
      errors.add(:base, "L'utilisateur doit avoir une adhésion cirque valide pour pratiquer")
      return
    end
    
    # Vérifie l'abonnement d'entraînement pour les pratiquants
    unless user_membership.subscription_type.category.in?(['day_pass', 'ten_sessions', 'quarterly', 'yearly'])
      errors.add(:base, "L'utilisateur doit avoir un abonnement d'entraînement valide pour pratiquer")
    end
  end

  def user_has_remaining_sessions
    if user_membership.remaining_sessions.to_i <= 0
      errors.add(:base, "L'utilisateur n'a plus de séances disponibles")
    end
  end

  def validate_no_active_subscription_with_day_pass
    return unless user_membership&.subscription_type&.category == 'day_pass'

    active_sub = user.user_memberships.active.joins(:subscription_type)
                    .where(subscription_types: { category: ['trimester', 'yearly'] })
                    .exists?
    
    errors.add(:base, "Un abonnement actif existe déjà") if active_sub
  end

  def decrement_sessions
    user_membership.decrement!(:remaining_sessions)
  end
end 