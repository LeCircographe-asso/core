module ApplicationHelper
  def current_user
    if authenticated?
      Current.user
    end
  end

  def authorized_roles
  end

  def admin_view?
  authenticated? && authorized_roles.include?(Current.user.role)
  end
end
