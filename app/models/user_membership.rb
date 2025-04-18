class UserMembership < ApplicationRecord
  enum :status, %i[active pending expired canceled], default: :pending
  belongs_to :membership
  belongs_to :user
  belongs_to :produit, optional: true
  belongs_to :order, optional: true

  before_update :expire_previous_memberships, if: -> { status_changed?(to: "active") }

  def activate!
    MembershipService.activate_membership(self)
  end
  
  def expire!
    MembershipService.expire_membership(self)
  end
  
  def cancel!
    MembershipService.cancel_membership(self)
  end
  
  def status_display_name
    MembershipHelper.membership_status_display_name(status)
  end
  
  def status_badge_class
    MembershipHelper.membership_status_badge_class(status)
  end
  
  def membership_type_display_name
    MembershipHelper.membership_type_display_name(membership.type_name)
  end
  
  def membership_type_badge_class
    MembershipHelper.membership_type_badge_class(membership.type_name)
  end

  private

  def expire_previous_memberships
    user.user_memberships.where(id: id).where(status: "active").update_all(status: "expired")
  end

end 