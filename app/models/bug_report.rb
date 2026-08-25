# frozen_string_literal: true

class BugReport < ApplicationRecord
  include AttachedImageValidatable

  enum :status, { new_report: 0, in_progress: 1, resolved: 2, wont_fix: 3 }, default: :new_report

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
