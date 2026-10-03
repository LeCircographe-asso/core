# frozen_string_literal: true

# Intérêt pour un événement : le « like » posé par un compte web via le bouton
# « Je suis intéressé ». Un simple compteur par personne, sans lien avec la
# présence (`Attendance`) ni avec la billetterie (`EventAttendee`).
class EventInterest < ApplicationRecord
  belongs_to :person
  belongs_to :event

  validates :person_id, uniqueness: { scope: :event_id }

  after_create_commit :broadcast_count
  after_destroy_commit :broadcast_count

  private

  def broadcast_count
    broadcast_replace_to(
      event,
      target: "event-#{event_id}-interest-count",
      partial: "events/interest_count",
      locals: { event: event, count: event.event_interests.count }
    )
  rescue => e
    Rails.logger.warn("[EventInterest] broadcast skipped: #{e.message}")
  end
end
