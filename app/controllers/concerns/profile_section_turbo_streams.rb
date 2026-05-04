# frozen_string_literal: true

# Builds Turbo Stream responses for embedded profile sections (contact + account).
module ProfileSectionTurboStreams
  extend ActiveSupport::Concern

  private

  def profile_contact_section_update_streams(user)
    [
      profile_contact_section_replace_action(user),
      profile_flash_replace_action
    ]
  end

  def profile_account_section_update_streams(user, embedded:, compact:)
    [
      profile_account_section_replace_action(user, embedded: embedded, compact: compact),
      profile_flash_replace_action
    ]
  end

  def profile_contact_section_replace_action(user)
    turbo_stream.replace(
      ProfileSectionDomIds::CONTACT_SECTION,
      render_to_string(
        partial: "users/contact_section",
        locals: {
          user: user,
          frame_id: ProfileSectionDomIds::CONTACT_SECTION
        }
      )
    )
  end

  def profile_account_section_replace_action(user, embedded:, compact:)
    turbo_stream.replace(
      ProfileSectionDomIds::ACCOUNT_SECTION,
      render_to_string(
        partial: "settings/account_section",
        locals: {
          user: user,
          frame_id: ProfileSectionDomIds::ACCOUNT_SECTION,
          embedded: embedded,
          compact: compact
        }
      )
    )
  end

  def profile_flash_replace_action
    turbo_stream.replace(
      ProfileSectionDomIds::FLASH_FRAME,
      render_to_string(partial: "shared/flash")
    )
  end
end
