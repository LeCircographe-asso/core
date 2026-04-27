class Event < ApplicationRecord
  include Categorizable
  include Dateable

  # Relations — voir docs/domain_model.md.
  belongs_to :creator, class_name: "User"
  has_many :attendances, dependent: :destroy
  has_many :people, through: :attendances
  # `event_attendees` reste réservé à la billetterie (paiement Stripe) — voir
  # docs/glossary.md. Les présences "registre" passent par `attendances`.
  has_many :event_attendees, dependent: :destroy
  # Validations
  validates :name, :date, presence: true
  validates :category, presence: true
  # Catégories — voir docs/glossary.md.
  enum :category, {
    show: 0,
    workshop: 1,
    volunteering: 2,
    other: 3
  }

  # Scopes
  scope :shows, -> { where(category: :show) }
  scope :workshops, -> { where(category: :workshop) }
  scope :volunteering, -> { where(category: :volunteering) }
  scope :others, -> { where(category: :other) }

  # Date scopes (using explicit :date column - datetime type)
  scope :upcoming, -> { where("date >= ?", Time.zone.now) }
  scope :past, -> { where("date < ?", Time.zone.now) }
  scope :today, -> { where("date >= ? AND date < ?", Date.current.beginning_of_day, Date.current.end_of_day) }
  scope :this_week, -> { where("date >= ? AND date <= ?", Date.current.beginning_of_week.beginning_of_day, Date.current.end_of_week.end_of_day) }
  scope :this_month, -> { where("date >= ? AND date <= ?", Date.current.beginning_of_month.beginning_of_day, Date.current.end_of_month.end_of_day) }
  scope :by_date, -> { order(:date) }

  # Méthodes
  def is_person_registered?(person)
    attendances.exists?(person: person)
  end

  # Présence "registre" : ne consulte jamais `event_attendees` (billetterie).
  def is_user_registered?(user)
    return false unless user&.person

    is_person_registered?(user.person)
  end

  # Méthode pour obtenir le nom (compatibilité)
  def title
    name
  end

  def title=(value)
    self.name = value
  end

  # Méthode pour obtenir la description unifiée
  def full_description
    description.presence || [ upper_description, middle_description, bottom_description ].compact.join("\n\n")
  end
end
