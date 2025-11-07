module EmailNormalizable
  extend ActiveSupport::Concern

  included do
    before_validation :normalize_email, if: :will_save_change_to_email?
  end

  private

  def normalize_email
    # Normalize blank emails to nil
    if email.blank?
      self.email = nil
      return
    end

    # Normalize non-blank emails (strip and downcase)
    self.email = email.strip.downcase
  end
end

