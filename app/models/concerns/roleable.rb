# frozen_string_literal: true

module Roleable
  extend ActiveSupport::Concern

  # [filename sous app/assets/images, alt text] — source unique, utilisée par
  # MembershipCardHelper et Admin::Members::MemberHeaderComponent.
  AVATARS = {
    "super_admin" => [ "super_admin.webp", "Avatar Super administrateur" ],
    "admin" => [ "admin.webp", "Avatar Administrateur" ],
    "volunteer" => [ "volunteer.webp", "Avatar Bénévole" ],
    "web_visitor" => [ "users.png", "Avatar Visiteur web" ]
  }.freeze
  DEFAULT_AVATAR = [ "users.png", "Avatar" ].freeze

  # Humanization des rôles
  def role_humanized
    case system_role
    when "super_admin" then "Super administrateur"
    when "admin" then "Administrateur"
    when "volunteer" then "Bénévole"
    when "web_visitor" then "Visiteur web"
    else system_role.humanize
    end
  end

  def avatar_filename
    avatar_source_and_alt.first
  end

  def avatar_alt
    avatar_source_and_alt.last
  end

  # Les prédicats de rôle exact (super_admin?, admin?, volunteer?, web_visitor?)
  # sont générés nativement par `enum :system_role` sur User — ne pas les
  # redéfinir ici (ça créerait un conflit silencieux, cf. docs/domain/role_permissions.md).

  # Droits d'administration élargis (super_admin OU admin). Pour l'accès brut
  # à la zone /admin (qui inclut aussi volunteer), voir User#can_access_admin_zone?.
  def can_administer?
    super_admin? || admin?
  end

  def can_manage_users?
    super_admin? || admin?
  end

  def can_manage_payments?
    super_admin? || admin? || volunteer?
  end

  # Restreint aux admin/super_admin : seul un rôle d'administration peut offrir
  # une adhésion/cotisation gratuite ou à prix réduit.
  def can_offer_items?
    super_admin? || admin?
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

  def can_manage_gallery?
    super_admin? || admin?
  end

  def can_manage_opening_hours?
    super_admin? || admin?
  end

  def can_manage_notepad?
    super_admin? || admin?
  end

  private

  def avatar_source_and_alt
    AVATARS.fetch(system_role, DEFAULT_AVATAR)
  end
end
