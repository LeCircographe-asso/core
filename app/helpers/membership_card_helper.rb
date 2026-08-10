# frozen_string_literal: true

# Shared presentation for `shared/_membershipcard` (role badge, avatar).
module MembershipCardHelper
  MEMBERSHIP_CARD_ROLE_BADGE_CLASSES = {
    "super_admin" => "bg-[#1F5C55]",
    "admin" => "bg-[#1F5C55]/90",
    "volunteer" => "bg-[#1F5C55]/80",
    "web_visitor" => "bg-[#1F5C55]/70"
  }.freeze

  def membership_card_role_badge_classes(system_role)
    MEMBERSHIP_CARD_ROLE_BADGE_CLASSES[system_role.to_s] || "bg-[#1F5C55]/70"
  end

  # @return [Array(String, String)] image filename under app/assets/images, alt text
  # Source unique : Roleable#avatar_filename / #avatar_alt (User).
  def membership_card_avatar_source_and_alt(user)
    [ user.avatar_filename, user.avatar_alt ]
  end

  def membership_card_display_name(user)
    user.full_name.presence || "Membre #{user.id}"
  end
end
