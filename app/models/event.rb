class Event < ApplicationRecord
  include Categorizable
  include Dateable
  
  # Relations selon le domain_model_circographe.md
  belongs_to :creator, class_name: "User"
  has_many :attendances, dependent: :destroy
  has_many :people, through: :attendances
  has_many :event_attendees, dependent: :destroy  # Legacy support
  # Validations
  validates :name, :date, presence: true
  validates :category, presence: true
  # Enum pour les catégories selon le domain_model_circographe.md
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
  scope :upcoming, -> { where("date >= ?", Date.current) }
  scope :past, -> { where("date < ?", Date.current) }
  scope :by_date, -> { order(:date) }

  # Méthodes
  def is_person_registered?(person)
    attendances.exists?(person: person)
  end

  # Méthode de compatibilité avec l'ancien système
  def is_user_registered?(user)
    # Essayer d'abord avec le nouveau système si user a une person
    if user.person
      is_person_registered?(user.person)
    else
      # Fallback sur l'ancien système
      event_attendees.exists?(user_id: user.id)
    end
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
