# frozen_string_literal: true

class AccountClaim < ApplicationRecord
  include Statusable
  include Dateable

  belongs_to :person
  belongs_to :user, optional: true

  has_secure_token :confirmation_token

  enum :status, { pending: 'pending', confirmed: 'confirmed', rejected: 'rejected', expired: 'expired' }

  validates :confirmation_token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :active, -> { where(status: :pending).where('expires_at > ?', Time.current) }

  # Override Dateable's expired? method to check expires_at instead of status
  def expired?
    Time.current > expires_at
  end
end
