class Attendance < ApplicationRecord
  include Dateable

  # Relations selon le domain_model_circographe.md
  belongs_to :person
  belongs_to :event, optional: true
  belongs_to :attendance_list, optional: true
  belongs_to :book_of_entry, optional: true
  # Validations
  validates :date, presence: true
  # Validation conditionnelle : pour les Events, on vérifie person_id + event_id
  validates :person_id, uniqueness: {
    scope: :event_id,
    message: "est déjà intéressé par cet événement"
  }, if: -> { event_id.present? }
  # Validation conditionnelle : pour les AttendanceList, on vérifie person_id + date
  validates :person_id, uniqueness: {
    scope: :date,
    message: "est déjà marqué présent aujourd'hui"
  }, if: -> { event_id.nil? }

  # validates :user_id, uniqueness: { scope: :attendance_list_id, message: "est déjà marqué présent dans cette liste" }, if: -> { user_id.present? && attendance_list_id.present? }

  # Callbacks
  before_create :set_date_if_missing
  after_create :decrement_book_of_entry, if: -> { attendance_list_id.present? }

  # Scopes spécifiques
  scope :by_person, ->(person) { where(person: person) }
  scope :by_event, ->(event) { where(event: event) }

  # Date scopes (using explicit :date column)
  scope :today, -> { where(date: Date.current) }
  scope :this_week, -> { where(date: Date.current.beginning_of_week..Date.current.end_of_week) }
  scope :this_month, -> { where(date: Date.current.beginning_of_month..Date.current.end_of_month) }

private

  def set_date_if_missing
    self.date ||= Date.current
  end

  def decrement_book_of_entry
    return unless book_of_entry

    book_of_entry.use_session!
  end
end
