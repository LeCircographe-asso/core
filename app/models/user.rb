class User < ApplicationRecord
  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles
  has_many :sessions, dependent: :destroy
  has_many :created_events, class_name: "Event", foreign_key: "creator_id"
  has_many :event_attendees, dependent: :destroy
  has_many :events, through: :event_attendees
  has_many :user_memberships
  has_many :subscription_types, through: :user_memberships
  has_many :training_attendees, through: :user_memberships
  has_many :payments, through: :user_memberships
  has_many :payments, through: :donations

  enum :role, %i[guest membership circus_membership volunteer admin godmode], default: :guest

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  has_secure_password
  validates :email_address, presence: true, uniqueness: true

  alias_attribute :email, :email_address

  after_create :welcome_send
  def welcome_send
    UserMailer.welcome_email(self).deliver_now
  end
  def has_privileges?
    [ "admin", "godmode", "volunteer" ].include? self.role
  end

  def is_interested_in?(event_id)
    events = self.event_attendees
    events.each do |event|
      if event.event_id == event_id
        return true
      end
    end
    false
  end
end
