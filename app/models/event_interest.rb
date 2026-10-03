# frozen_string_literal: true

# Intérêt pour un événement : le « like » posé par un compte web via le bouton
# « Je suis intéressé ». Un simple compteur, indépendant de toute autre logique
# métier (présences, inscriptions).
class EventInterest < ApplicationRecord
  belongs_to :user
  belongs_to :event

  validates :user_id, uniqueness: { scope: :event_id }

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
