# frozen_string_literal: true

# Shared presentation for `shared/_membershipcard` (role badge, avatar).
module MembershipCardHelper
  MEMBERSHIP_CARD_ROLE_BADGE_CLASSES = {
    "super_admin" => "bg-brand-primary",
    "admin" => "bg-brand-primary/90",
    "volunteer" => "bg-brand-primary/80"
  }.freeze

  def membership_card_role_badge_classes(system_role)
    MEMBERSHIP_CARD_ROLE_BADGE_CLASSES[system_role.to_s] || "bg-brand-primary/70"
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
