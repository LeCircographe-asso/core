class Payment < ApplicationRecord
  belongs_to :user
  belongs_to :order

  validates :user_id, presence: true
  validates :order_id, presence: true

  enum :status, %i[
    success
    pending
    cancel
  ], default: :pending

  enum :payment_type, %i[
    cash
    credit_card
    check
  ]
end
