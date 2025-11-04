module EmailNormalizable
  extend ActiveSupport::Concern

  included do
    before_validation :normalize_email, if: :will_save_change_to_email?
  end

  private

  def normalize_email
    return unless email.present?

    self.email = email.strip.downcase
  end
end

