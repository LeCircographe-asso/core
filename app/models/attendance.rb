# frozen_string_literal: true

class Attendance < ApplicationRecord
  include Dateable

  belongs_to :person
  belongs_to :event, optional: true
  belongs_to :attendance_list, optional: true
  belongs_to :contribution, optional: true

  validates :date, presence: true
  validate :person_already_present_that_day

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

  # Reflète la contrainte unique réelle en base (person_id, date), indépendante
  # de l'event_id : une personne n'a qu'une seule présence par jour, que ce soit
  # un entraînement ou l'intérêt pour un événement. L'ancienne validation ne
  # vérifiait l'unicité que par event_id, ce qui laissait passer un second
  # enregistrement le même jour (ex. intérêt pour un 2e événement) jusqu'au
  # crash en base (ActiveRecord::RecordNotUnique) au lieu d'une erreur propre.
  def person_already_present_that_day
    return if person_id.blank? || date.blank?

    existing = Attendance.where(person_id: person_id, date: date).where.not(id: id).first
    return unless existing

    if event_id.present? && existing.event_id == event_id
      errors.add(:person_id, :event_interest_taken)
    else
      errors.add(:person_id, :daily_presence_taken)
    end
  end

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
