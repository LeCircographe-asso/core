# frozen_string_literal: true

class Attendance < ApplicationRecord
  include Dateable

  belongs_to :person
  belongs_to :event, optional: true
  belongs_to :attendance_list, optional: true
  belongs_to :contribution, optional: true

  validates :date, presence: true
  validates :person_id, uniqueness: {
    scope: :event_id,
    message: :event_interest_taken
  }, if: -> { event_id.present? }
  validates :person_id, uniqueness: {
    scope: :date,
    message: :daily_presence_taken
  }, if: -> { event_id.nil? }

  before_create :set_date_if_missing
  after_create :decrement_contribution, if: -> { attendance_list_id.present? }
  after_create_commit :broadcast_interest_count, if: -> { event_id.present? }
  after_destroy_commit :broadcast_interest_count, if: -> { event_id.present? }

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

  def broadcast_interest_count
    count = event.people.reload.count
    broadcast_replace_to(
      event,
      target: "event-#{event_id}-interest-count",
      partial: "events/interest_count",
      locals: { event: event, count: count }
    )
  rescue => e
    Rails.logger.warn("[Attendance] broadcast skipped: #{e.message}")
  end
end
