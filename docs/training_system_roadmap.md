# Système de Gestion des Entraînements - Roadmap

## 1. Modèles et Migrations

### TrainingSession
```ruby
class TrainingSession < ApplicationRecord
  belongs_to :recorded_by, class_name: 'User'
  has_many :training_attendees, dependent: :destroy
  has_many :users, through: :training_attendees

  validates :date, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[open closed] }
  validates :max_capacity, numericality: { greater_than: 0 }

  scope :today, -> { where(date: Date.current) }
  scope :open, -> { where(status: 'open') }
end
```

### TrainingAttendee
```ruby
class TrainingAttendee < ApplicationRecord
  belongs_to :user
  belongs_to :training_session
  belongs_to :user_membership, optional: true
  belongs_to :recorded_by, class_name: 'User'

  validates :user_id, uniqueness: { scope: :training_session_id }
  validate :user_can_train
  validate :session_not_full

  after_create :decrement_entries_count, if: -> { user_membership&.booklet? }
end
```

## 2. Logique Métier

### Services
```ruby
class TrainingSessionService
  def self.create_daily_session
    TrainingSession.create!(
      date: Date.current,
      status: 'open',
      max_capacity: 30,
      recorded_by: User.admin.first
    )
  end

  def self.close_expired_sessions
    TrainingSession.where('date < ?', Date.current)
                  .update_all(status: 'closed')
  end
end

class UserMembershipService
  def self.can_train?(user)
    return false unless user.active_circus_membership?
    return false if user.already_trained_today?
    return false if user.current_subscription.nil?
    
    true
  end
end
```

## 3. Interface Admin

### Vues
- Dashboard principal (`index.html.erb`)
- Partials pour statistiques et liste des présents
- Formulaire de recherche avec Turbo
- Modales de confirmation

### Contrôleur
```ruby
class Admin::TrainingDashboardController < Admin::BaseController
  def index
    @current_session = TrainingSession.current_or_create
    @stats = calculate_stats
    @attendees = @current_session.attendees.includes(:user)
  end

  def add_attendee
    # Logique d'ajout
  end

  def remove_attendee
    # Logique de retrait
  end
end
```

## 4. Tests 