class Payment < ApplicationRecord
  belongs_to :user
  belongs_to :product_order

  validates :user_id, presence: true

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

  after_create :update_user_membership_if_paid

  def update_user_membership_if_paid
    return unless status == "success"

    self.product_order.order.update_user_membership_if_paid
  end

end
