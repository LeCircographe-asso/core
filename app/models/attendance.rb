class Attendance < ApplicationRecord
  include Dateable

  belongs_to :person
  belongs_to :event, optional: true
  belongs_to :attendance_list, optional: true
  belongs_to :contribution, optional: true

  validates :date, presence: true
  validates :person_id, uniqueness: {
    scope: :event_id,
    message: "est déjà intéressé par cet événement"
  }, if: -> { event_id.present? }
  validates :person_id, uniqueness: {
    scope: :date,
    message: "est déjà marqué présent aujourd'hui"
  }, if: -> { event_id.nil? }

  before_create :set_date_if_missing
  after_create :decrement_contribution, if: -> { attendance_list_id.present? }

  scope :by_person, ->(person) { where(person: person) }
  scope :by_event, ->(event) { where(event: event) }

  scope :today, -> { where(date: Date.current) }
  scope :this_week, -> { where(date: Date.current.beginning_of_week..Date.current.end_of_week) }
  scope :this_month, -> { where(date: Date.current.beginning_of_month..Date.current.end_of_month) }

private

  def set_date_if_missing
    self.date ||= Date.current
  end

  def decrement_contribution
    return unless contribution

    contribution.use_session!
  end
end
