class Event < ApplicationRecord
  belongs_to :creator, class_name: "User", foreign_key: :user_id
  has_many :event_attendees, dependent: :destroy
  has_many :users, through: :event_attendees

  validates :title, :date, presence: true

  def is_user_registered?(user)
    event_attendees.exists?(user_id: user.id)
  end
end
