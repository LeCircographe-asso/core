class Event < ApplicationRecord
  belongs_to :creator, class_name: 'User'
  has_many :event_attendees, dependent: :destroy
  has_many :users, through: :event_attendees


  validates :title, :date, presence: true
end
