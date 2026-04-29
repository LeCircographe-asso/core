require 'ostruct'

module People
  class AccountLinker
    include ActiveModel::Model
    include ActiveModel::Attributes

    Result = Struct.new(:success?, :user, :target_person, :source_person, :errors, :message, keyword_init: true)

    attr_accessor :user, :target_person, :source_person

    attribute :user_id, :integer
    attribute :target_person_id, :integer
    attribute :destroy_source_person, :boolean, default: false
    attribute :anonymize_source_person, :boolean, default: true
    attribute :audit_reason, :string, default: 'manual_link'

    validates :user_id, presence: true, unless: -> { user.present? }
    validates :target_person_id, presence: true, unless: -> { target_person.present? }

    def call
      return failure("Invalid data: #{errors.full_messages.join(', ')}") unless valid?

      resolved_user = resolve_user
      resolved_target = resolve_target_person
      previous_person = resolved_user.person

      return failure('User already linked to this person') if previous_person == resolved_target

      return failure('Target person already has a user account') if resolved_target.user.present? && resolved_target.user != resolved_user

      ActiveRecord::Base.transaction do
        resolved_user.update!(person: resolved_target)

        cleanup_source_person(previous_person) if previous_person.present? && previous_person != resolved_target

        instrument_success(resolved_user, resolved_target, previous_person)

        success(user: resolved_user, target_person: resolved_target, source_person: previous_person)
      end
    rescue ActiveRecord::RecordNotFound => e
      failure("Record not found: #{e.message}")
    rescue ActiveRecord::RecordInvalid => e
      failure("Validation error: #{e.message}")
    rescue StandardError => e
      Rails.logger.error("[People::AccountLinker] #{e.class}: #{e.message}\n#{e.backtrace.take(5).join("\n")}")
      failure("Error linking account: #{e.message}")
    end

    private

    def resolve_user
      return user if user.present?

      User.find(user_id)
    end

    def resolve_target_person
      return target_person if target_person.present?

      Person.find(target_person_id)
    end

    def cleanup_source_person(previous_person)
      return unless destroy_source_person

      previous_person.update!(email: nil, phone: nil) if anonymize_source_person

      previous_person.destroy!
    end

    def instrument_success(user, target_person, source_person)
      ActiveSupport::Notifications.instrument(
        'people.account_linked',
        user_id: user.id,
        target_person_id: target_person.id,
        source_person_id: source_person&.id,
        destroy_source_person: destroy_source_person,
        audit_reason: audit_reason
      )
    end

    def success(user:, target_person:, source_person: nil)
      Result.new(success?: true, user: user, target_person: target_person, source_person: source_person, errors: [], message: 'User linked successfully')
    end

    def failure(message, errors = nil)
      Result.new(success?: false, user: nil, target_person: nil, source_person: nil, errors: Array(errors || message), message: message)
    end
  end
end
