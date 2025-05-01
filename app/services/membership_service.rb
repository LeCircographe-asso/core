class MembershipService
  def self.assign_basic_membership(user)
    basic_membership = Membership.find_by(type_name: :Basic)
    return false unless basic_membership
    
    user.user_memberships.create(membership: basic_membership)
  end
  
  def self.activate_membership(user_membership)
    return false unless user_membership
    
    # Expire previous active memberships
    user_membership.user.user_memberships
                   .where.not(id: user_membership.id)
                   .where(status: :active)
                   .update_all(status: :expired)
    
    user_membership.update(status: :active)
  end
  
  def self.expire_membership(user_membership)
    return false unless user_membership
    
    user_membership.update(status: :expired)
  end
  
  def self.cancel_membership(user_membership)
    return false unless user_membership
    
    user_membership.update(status: :canceled)
  end
  
  def self.active_memberships_count
    UserMembership.where(status: :active).count
  end
  
  def self.membership_type_count(type_name)
    UserMembership.joins(:membership)
                  .where(memberships: { type_name: type_name }, status: :active)
                  .count
  end


end 