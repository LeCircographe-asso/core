class AccountClaim < ApplicationRecord
  belongs_to :person
  belongs_to :user, optional: true

  has_secure_token :confirmation_token

  enum :status, { pending: "pending", confirmed: "confirmed", rejected: "rejected", expired: "expired" }

  validates :confirmation_token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :active, -> { where(status: :pending).where("expires_at > ?", Time.current) }

  def expired?
    Time.current > expires_at
  end
end
