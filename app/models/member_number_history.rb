class MemberNumberHistory < ApplicationRecord
  belongs_to :person

  validates :member_number, presence: true, uniqueness: true
  validates :membership_type, presence: true, inclusion: { in: %w[Cirque Basique] }
  validates :year, presence: true, numericality: { greater_than: 2000, less_than: 2100 }
  validates :assigned_at, presence: true

  scope :current, -> { where(replaced_at: nil) }
  scope :historical, -> { where.not(replaced_at: nil) }
  scope :by_year, ->(year) { where(year: year) }
  scope :by_type, ->(type) { where(membership_type: type) }

  # Retourne le numéro d'adhérent actuel pour une Person
  def self.current_for_person(person)
    where(person: person, replaced_at: nil).first
  end

  # Retourne l'historique complet pour une Person
  def self.history_for_person(person)
    where(person: person).order(:assigned_at)
  end

  # Marque ce numéro comme remplacé
  def mark_as_replaced!
    update!(replaced_at: Time.current)
  end

  # Vérifie si c'est le numéro actuel
  def current?
    replaced_at.nil?
  end

  # Retourne la durée d'utilisation
  def duration
    end_time = replaced_at || Time.current
    end_time - assigned_at
  end

  # Retourne les détails du numéro
  def parsed_number
    MemberManagementService.parse_member_number(member_number)
  end

  # Affiche le numéro de manière lisible
  def formatted_number
    parsed = parsed_number
    return member_number unless parsed
    
    "#{parsed[:year]} - #{parsed[:type]} - ##{parsed[:number]}"
  end
end
