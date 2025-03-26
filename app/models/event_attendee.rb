class EventAttendee < ApplicationRecord
  belongs_to :user
  belongs_to :event
  belongs_to :payment

  validates :user_id, :event_id, presence: true
end
