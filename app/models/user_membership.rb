class UserMembership < ApplicationRecord
  belongs_to :user
  belongs_to :subscription_type
  belongs_to :payment, optional: true

  has_many :payments, dependent: :destroy
  has_many :training_attendees

  validates :user_id, :subscription_type_id, presence: true
end
