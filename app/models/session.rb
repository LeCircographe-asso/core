# frozen_string_literal: true

class Session < ApplicationRecord
  # Bounds writes to one per minute per active session; idle detection is
  # therefore precise to about a minute.
  ACTIVITY_THROTTLE = 1.minute

  belongs_to :user

  def idle_expired?(now = Time.current)
    timeout = user.idle_timeout
    timeout.present? && updated_at < now - timeout
  end

  def track_activity!(now = Time.current)
    touch if updated_at < now - ACTIVITY_THROTTLE
  end
end
