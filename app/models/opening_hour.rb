class OpeningHour < ApplicationRecord
  enum :day, %i[
    monday
    tuesday
    wednesday
    thursday
    friday
    saturday
    sunday
]

  validates :day, presence: true
  validates :opens_at, presence: true
  validates :closes_at, presence: true
  validate :closing_after_opening

  private

  def closing_after_opening
    if closes_at <= opens_at
      errors.add(:closes_at, "doit être après l'heure d'ouverture")
    end
  end
end
