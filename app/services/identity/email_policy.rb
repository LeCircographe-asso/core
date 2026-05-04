# frozen_string_literal: true

module Identity
  class EmailPolicy
    def self.person_email_conflicts_with_other_user?(email:, current_person_id:)
      normalized_email = normalize(email)
      return false if normalized_email.blank?

      User.where(email_address: normalized_email)
          .where.not(person_id: current_person_id)
          .exists?
    end

    def self.user_email_conflicts_with_other_person?(email:, current_person_id:)
      normalized_email = normalize(email)
      return false if normalized_email.blank?

      Person.where(email: normalized_email)
            .where.not(id: current_person_id)
            .exists?
    end

    def self.normalize(email)
      email.to_s.strip.downcase
    end
    private_class_method :normalize
  end
end
