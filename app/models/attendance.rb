# frozen_string_literal: true

class Attendance < ApplicationRecord
  include Dateable

  belongs_to :person
  belongs_to :event, optional: true
  belongs_to :attendance_list, optional: true
  belongs_to :contribution, optional: true

  validates :date, presence: true
  # Présence d'entraînement unique par jour. Le « like » d'un événement ne vit
  # plus ici mais dans `EventInterest`.
  validates :person_id, uniqueness: { scope: :event_id, message: :event_presence_taken }, if: -> { event_id.present? }
  validates :person_id, uniqueness: { scope: :date, message: :daily_presence_taken }, if: -> { event_id.nil? }

  before_create :set_date_if_missing
  after_create :decrement_contribution, if: -> { attendance_list_id.present? }

  scope :by_person, ->(person) { where(person: person) }
  scope :by_event, ->(event) { where(event: event) }

  scope :today, -> { where(date: Date.current) }
  scope :this_week, -> { where(date: Date.current.all_week) }
  scope :this_month, -> { where(date: Date.current.all_month) }

  private

  def set_date_if_missing
    self.date ||= Date.current
  end

  def decrement_contribution
    return unless contribution

    contribution.use_session!
  end
end
