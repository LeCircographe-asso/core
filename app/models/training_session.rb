class TrainingSession < ApplicationRecord
  belongs_to :recorded_by, class_name: 'User', optional: true
  
  has_many :training_attendees, dependent: :destroy
  has_many :users, through: :training_attendees
  
  validates :date, presence: true, uniqueness: true
  
  enum :status, {
    open: "open",      # Journée en cours
    closed: "closed",  # Journée terminée
    holiday: "holiday" # Jour férié ou fermeture exceptionnelle
  }, default: :open
  
  # Scope pour trouver la session du jour
  scope :today, -> { find_or_create_by(date: Date.current) do |session|
    session.status = :open
  end }
  
  # Scope pour les statistiques
  scope :between_dates, ->(start_date, end_date) { where(date: start_date..end_date) }
  scope :this_month, -> { where(date: Date.current.beginning_of_month..Date.current.end_of_month) }
  
  def attendance_count
    training_attendees.count
  end
end 