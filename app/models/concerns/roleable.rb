module Roleable
  extend ActiveSupport::Concern

  # Humanization des rôles
  def role_humanized
    case system_role
    when "super_admin" then "Super Admin"
    when "admin" then "Admin"
    when "volunteer" then "Bénévole"
    when "web_visitor" then "Visiteur Web"
    else system_role.humanize
    end
  end

  # Vérifications de rôle
  def super_admin?
    system_role == "super_admin"
  end

  def admin?
    system_role == "admin"
  end

  def volunteer?
    system_role == "volunteer"
  end

  def web_visitor?
    system_role == "web_visitor"
  end

  def has_admin_rights?
    super_admin? || admin?
  end

  def can_manage_users?
    super_admin? || admin?
  end

  def can_manage_payments?
    super_admin? || admin? || volunteer?
  end

  def can_offer_items?
    super_admin? || admin? || volunteer?
  end

  def can_edit_member_numbers?
    super_admin? || admin?
  end

  def can_manage_attendance_lists?
    super_admin? || admin? || volunteer?
  end

  def can_manage_events?
    super_admin? || admin? || volunteer?
  end

  def can_manage_blogs?
    super_admin? || admin?
  end

  def can_manage_opening_hours?
    super_admin? || admin?
  end

  def can_manage_notepad?
    super_admin? || admin?
  end

  # Méthodes de classe pour les humanizations
  class_methods do
    def humanize_role(role)
      case role.to_s
      when "super_admin" then "Super Admin"
      when "admin" then "Admin"
      when "volunteer" then "Bénévole"
      when "web_visitor" then "Visiteur Web"
      else role.to_s.humanize
      end
    end

    def role_badge_class(role)
      case role.to_s
      when "super_admin" then "bg-purple-100 text-purple-800"
      when "admin" then "bg-blue-100 text-blue-800"
      when "volunteer" then "bg-green-100 text-green-800"
      when "web_visitor" then "bg-gray-100 text-gray-800"
      else "bg-gray-100 text-gray-800"
      end
    end
  end
end
