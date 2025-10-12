class UserService
  def self.create_user_with_membership(user_params, created_by_admin = false)
    user = User.new(user_params)
    user.created_by_admin = created_by_admin
    user.password = SecureRandom.hex(10) if created_by_admin

    User.transaction do
      if user.save
        # Create default membership
        default_membership = Membership.find_by(type_name: :No_Member)
        UserMembership.create!(user: user, membership: default_membership)

        # Create initial order
        order = user.orders.create!

        return { success: true, user: user, order: order }
      else
        return { success: false, errors: user.errors.full_messages }
      end
    end
  end

  def self.update_user_role(user, new_role)
    return { success: false, message: "Utilisateur non trouvé" } unless user

    if user.update(system_role: new_role)
      { success: true, user: user }
    else
      { success: false, errors: user.errors.full_messages }
    end
  end

  def self.users_count_by_period(start_date, end_date)
    User.where(created_at: start_date..end_date).count
  end

  def self.new_users_count
    users_count_by_period(1.day.ago.beginning_of_day, 1.day.ago.end_of_day)
  end

  def self.users_this_month
    users_count_by_period(Time.current.beginning_of_month, Time.current)
  end

  def self.users_with_active_memberships
    User.joins(:user_memberships).where(user_memberships: { status: :active }).distinct
  end
end
