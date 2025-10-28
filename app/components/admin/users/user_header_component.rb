class Admin::Users::UserHeaderComponent < ViewComponent::Base
  def initialize(user:, person:, is_person_without_user: false, is_deleted: false)
    @user = user
    @person = person
    @is_person_without_user = is_person_without_user
    @is_deleted = is_deleted
  end

  private

  attr_reader :user, :person, :is_person_without_user, :is_deleted

  def user_name
    user.full_name.present? ? user.full_name : "Utilisateur ##{user.id}"
  end

  def user_email
    user.email_address
  end

  def role_badge_class
    case user.system_role
    when "super_admin" then "bg-[#1F5C55]"
    when "admin" then "bg-[#1F5C55]/90"
    when "volunteer" then "bg-[#1F5C55]/80"
    when "web_visitor" then "bg-[#1F5C55]/70"
    else "bg-orange-500"
    end
  end

  def role_text
    if is_person_without_user
      "Créer un espace utilisateur"
    elsif user.system_role.present?
      case user.system_role
      when "volunteer" then "Bénévole"
      when "super_admin" then "Super Admin"
      when "admin" then "Admin"
      when "web_visitor" then "Visiteur Web"
      else user.system_role.humanize
      end
    else
      "Créer un espace utilisateur"
    end
  end

  def avatar_image
    case user.system_role
    when "super_admin" then "super_admin.webp"
    when "admin" then "admin.webp"
    when "volunteer" then "volunteer.webp"
    when "web_visitor" then "users.png"
    else "users.png"
    end
  end

  def avatar_alt
    case user.system_role
    when "super_admin" then "Avatar Super Admin"
    when "admin" then "Avatar Admin"
    when "volunteer" then "Avatar Bénévole"
    when "web_visitor" then "Avatar Utilisateur"
    else "Avatar"
    end
  end
end
