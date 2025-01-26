class SubscriptionType < ApplicationRecord
  has_many :user_membership_subscriptions
  has_many :user_memberships, through: :user_membership_subscriptions

  # Validations de base
  validates :name, presence: true, uniqueness: true
  validates :price, presence: true, 
                   numericality: { greater_than_or_equal_to: 0 }
  validates :category, presence: true
  validates :active, inclusion: { in: [true, false] }
  validates :duration_type, presence: true, inclusion: { in: ['days', 'months', 'years', 'sessions'] }
  validates :duration_value, presence: true, numericality: { greater_than: 0 }
  
  # Validation personnalisée pour les prix
  validate :validate_subscription_prices
  
  # Types d'adhésion/abonnement
  enum :category, {
    basic_membership: 0,     # Adhésion simple (1€)
    circus_membership: 1,    # Adhésion cirque (10€)
    day_pass: 2,            # Pass journée (4€)
    ten_sessions: 3,        # Pack 10 séances (30€)
    quarterly: 4,           # Abonnement trimestriel (65€)
    yearly: 5              # Abonnement annuel (150€)
  }

  # Scopes utiles
  scope :active_only, -> { where(active: true) }
  scope :memberships, -> { where(category: [:basic_membership, :circus_membership]) }
  scope :training_passes, -> { where(category: [:day_pass, :ten_sessions, :quarterly, :yearly]) }
  scope :available_for_purchase, -> { active_only.where.not(category: [:basic_membership, :circus_membership]) }
  
  def requires_circus_membership?
    training_passes.include?(category)
  end
  
  def has_limited_sessions?
    has_limited_sessions
  end
  
  def has_expiration_date?
    duration_type != 'sessions'
  end
  
  def has_expiration?
    !ten_sessions?
  end
  
  def duration_in_days
    case category
    when 'day_pass' then 1
    when 'quarterly' then 90
    when 'yearly' then 365
    else nil
    end
  end
  
  private
  
  def validate_subscription_prices
    case category.to_sym
    when :basic_membership
      errors.add(:price, "doit être de 1€ pour l'adhésion simple") unless price == 1
    when :circus_membership
      errors.add(:price, "doit être de 10€ pour l'adhésion cirque") unless price == 10
    when :day_pass
      errors.add(:price, "doit être de 4€") unless price == 4
    when :ten_sessions
      errors.add(:price, "doit être de 30€") unless price == 30
    when :quarterly
      errors.add(:price, "doit être de 65€") unless price == 65
    when :yearly
      errors.add(:price, "doit être de 150€") unless price == 150
    end
  end
end
