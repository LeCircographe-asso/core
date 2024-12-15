class UserMembership < ApplicationRecord
  belongs_to :user

  # has_many :payments, dependent: :destroy
  has_many :training_attendees
  has_many :user_membership_subscriptions
  has_many :subscription_types, through: :user_membership_subscriptions


  validates :user_id, :subscription_type_id, presence: true
end
