class UserMembership < ApplicationRecord

  enum :status, %i[active pending expired canceled], default: :pending
  belongs_to :membership
  belongs_to :user
  belongs_to :produit, optional: true
  belongs_to :order, optional: true

  before_update :expire_previous_memberships, if: -> { status_changed?(to: "active") }

  private

  def expire_previous_memberships
    user.user_memberships.where(id: id).where(status: "active").update_all(status: "expired")
  end

end 