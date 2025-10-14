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
    Membership.where(status: 'active').count
  end

  def self.membership_type_count(type_name)
    # Adapter au nouveau modèle Person-Based
    case type_name.to_s.downcase
    when 'basic'
      Membership.joins(:membership_type)
                .where(membership_types: { category: 'basic' }, status: 'active')
                .count
    when 'circus'
      Membership.joins(:membership_type)
                .where(membership_types: { category: ['circus_full', 'circus_reduced'] }, status: 'active')
                .count
    else
      0
    end
  end
end
