class Donation < ApplicationRecord
  belongs_to :user
  belongs_to :payment
  has_many :payments, dependent: :destroy
end
