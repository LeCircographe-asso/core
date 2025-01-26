class Payment < ApplicationRecord
  belongs_to :user
  belongs_to :recorded_by, class_name: 'User', optional: true
  
  has_one :user_membership
  has_one :donation
  has_many :event_attendees
  
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :payment_method, presence: true
  validates :status, presence: true
  
  enum status: {
    pending: 'pending',       # En attente
    completed: 'completed',   # Payé
    cancelled: 'cancelled',   # Annulé
    refunded: 'refunded'      # Remboursé
  }
  
  enum payment_method: {
    cash: 'cash',           # Espèces
    card: 'card',           # Carte bancaire
    check: 'check',         # Chèque
    transfer: 'transfer'    # Virement
  }
  
  # Scopes utiles
  scope :successful, -> { where(status: 'completed') }
  scope :by_date, ->(date) { where('DATE(created_at) = ?', date) }
  scope :by_period, ->(start_date, end_date) { where(created_at: start_date..end_date) }
  
  def total_amount
    amount + donation_amount
  end
  
  def has_donation?
    donation_amount > 0
  end
end
