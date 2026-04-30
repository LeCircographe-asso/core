# frozen_string_literal: true

require "ostruct"

module People
  class AttachUserToPerson
    include ActiveModel::Model
    include ActiveModel::Attributes

    Result = Struct.new(:success?, :user, :person, :errors, :message, keyword_init: true)

    attr_accessor :user, :person

    attribute :user_id, :integer
    attribute :person_id, :integer
    attribute :audit_reason, :string, default: "manual_attach"

    validates :user_id, presence: true, unless: -> { user.present? }
    validates :person_id, presence: true, unless: -> { person.present? }

    def call
      return failure(I18n.t("services.validation.invalid_data_with_details", details: errors.full_messages.join(", "))) unless valid?

      resolved_user = user.presence || User.find(user_id)
      resolved_person = person.presence || Person.find(person_id)

      return success(resolved_user, resolved_person, "User already attached to this person") if resolved_user.person == resolved_person
      return failure("Target person already has a user account") if resolved_person.user.present? && resolved_person.user != resolved_user

      ActiveRecord::Base.transaction do
        resolved_user.update!(person: resolved_person)

        ActiveSupport::Notifications.instrument(
          "people.user_attached",
          user_id: resolved_user.id,
          person_id: resolved_person.id,
          audit_reason: audit_reason
        )

        success(resolved_user, resolved_person, "User attached successfully")
      end
    rescue ActiveRecord::RecordNotFound => e
      failure("Record not found: #{e.message}")
    rescue ActiveRecord::RecordInvalid => e
      failure("Validation error: #{e.message}")
    rescue StandardError => e
      Rails.logger.error("[People::AttachUserToPerson] #{e.class}: #{e.message}\n#{e.backtrace.take(5).join("\n")}")
      failure("Error attaching user: #{e.message}")
    end

    private

    def success(user, person, message)
      Result.new(success?: true, user: user, person: person, errors: [], message: message)
    end

    def failure(message, error_list = nil)
      Result.new(success?: false, user: nil, person: nil, errors: Array(error_list || message), message: message)
    end
  end
end
