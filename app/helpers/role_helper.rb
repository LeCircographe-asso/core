module RoleHelper
  def role_badge_class(role)
    case role.to_sym
    when :super_admin
      "bg-purple-100 text-purple-800"
    when :admin
      "bg-blue-100 text-blue-800"
    when :volunteer
      "bg-green-100 text-green-800"
    when :user_connected
      "bg-gray-100 text-gray-800"
    else
      "bg-gray-100 text-gray-800"
    end
  end
  
  def role_display_name(role)
    case role.to_sym
    when :super_admin
      "Super Administrateur"
    when :admin
      "Administrateur"
    when :volunteer
      "Volontaire"
    when :user_connected
      "Utilisateur"
    else
      role.to_s.humanize
    end
  end
  
  def can_manage_users?
    current_user&.has_privileges?
  end
  
  def can_edit_user?(user)
    return false unless current_user && user
    
    current_user.has_higher_permissions?(user)
  end
  
  def available_roles_for_user(user)
    return [] unless current_user && user
    
    if current_user.has_higher_permissions?(user)
      current_user.inferior_rights
    else
      [user.system_role]
    end
  end
end 