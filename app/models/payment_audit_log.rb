# frozen_string_literal: true

class PaymentAuditLog < ApplicationRecord
  belongs_to :payment
  belongs_to :user, optional: true

  validates :action, presence: true

  # Action types: create, update, delete

  # Create a log entry for payment changes
  def self.log(payment, user, action, change_data = {})
    create(
      payment: payment,
      user: user,
      action: action,
      change_data: change_data.to_json
    )
  end
end
