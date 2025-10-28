class Attendance < ApplicationRecord
  include Dateable
  
  # Relations selon le domain_model_circographe.md
  belongs_to :person
  belongs_to :event, optional: true
  # Validations
  validates :date, presence: true
  validates :person_id, uniqueness: { scope: :date, message: "est déjà marqué présent aujourd'hui" }

  # validates :user_id, uniqueness: { scope: :attendance_list_id, message: "est déjà marqué présent dans cette liste" }, if: -> { user_id.present? && attendance_list_id.present? }

  # Callbacks
  before_create :set_date_if_missing
  after_create :decrement_book_of_entry

  # Scopes
  scope :today, -> { where(date: Date.current) }
  scope :this_week, -> { where(date: Date.current.beginning_of_week..Date.current.end_of_week) }
  scope :this_month, -> { where(date: Date.current.beginning_of_month..Date.current.end_of_month) }
  scope :by_person, ->(person) { where(person: person) }
  scope :by_event, ->(event) { where(event: event) }

private

  def set_date_if_missing
    self.date ||= Date.current
  end

  def decrement_book_of_entry
    return unless book_of_entry

    # Utiliser la nouvelle méthode du modèle BookOfEntry
    if book_of_entry.respond_to?(:use_session!)
      book_of_entry.use_session!
    else
      # Ancienne logique pour compatibilité
      if book_of_entry.remaining > 0
        book_of_entry.update(remaining: book_of_entry.remaining - 1)

        if book_of_entry.remaining <= 0
          book_of_entry.update(status: :inactive)
        end
      end
    end
  end
end
