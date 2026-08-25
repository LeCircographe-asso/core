# frozen_string_literal: true

class BugReport < ApplicationRecord
  include AttachedImageValidatable

  enum :status, { new_report: 0, in_progress: 1, resolved: 2, wont_fix: 3 }, default: :new_report
  enum :device_type, { mobile: "mobile", desktop: "desktop" }, validate: { allow_nil: true }
  enum :display_mode, { browser: "browser", standalone: "standalone" }, validate: { allow_nil: true }
  enum :reporter_role, { super_admin: "super_admin", admin: "admin", volunteer: "volunteer", web_visitor: "web_visitor" }, validate: { allow_nil: true }

  belongs_to :person, optional: true
  has_one_attached :screenshot

  validates :note, presence: true
  validate :validate_screenshot

  scope :ordered, -> { order(created_at: :desc) }

  private

  def validate_screenshot
    validate_image_attachment(screenshot)
  end
end
