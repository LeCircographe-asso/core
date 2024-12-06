class Payment < ApplicationRecord

  has_many :users, through: :donations
  # validates :payment_method, :amount, presence: true
end
