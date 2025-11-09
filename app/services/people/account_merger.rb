require "ostruct"

module People
  class AccountMerger
    include ActiveModel::Model
    include ActiveModel::Attributes

    Result = Struct.new(:success?, :source_person, :target_person, :errors, :message, keyword_init: true)

    attr_accessor :source_person, :target_person

    attribute :source_person_id, :integer
    attribute :target_person_id, :integer
    attribute :actor_id, :integer
    attribute :merge_type, :string, default: "manual"
    attribute :destroy_source, :boolean, default: true

    validates :source_person_id, presence: true, unless: -> { source_person.present? }
    validates :target_person_id, presence: true, unless: -> { target_person.present? }

    def call
      return failure("Invalid data: #{errors.full_messages.join(', ')}") unless valid?

      source = resolve_source_person
      target = resolve_target_person

      if source == target
        return failure("Source and target persons are identical")
      end

      ActiveRecord::Base.transaction do
        merge_memberships(source, target)
        merge_payments(source, target)
        merge_subscriptions(source, target)
        merge_newsletter(source, target)
        merge_attributes(source, target)

        if destroy_source
          source.destroy!
        else
          source.update!(user: nil)
        end

        instrument_success(source, target)

        success(source_person: source, target_person: target)
      end
    rescue ActiveRecord::RecordNotFound => e
      failure("Record not found: #{e.message}")
    rescue ActiveRecord::RecordInvalid => e
      failure("Validation error: #{e.message}")
    rescue => e
      Rails.logger.error("[People::AccountMerger] #{e.class}: #{e.message}\n#{e.backtrace.take(5).join("\n")}")
      failure("Error merging accounts: #{e.message}")
    end

    private

    def resolve_source_person
      return source_person if source_person.present?

      Person.find(source_person_id)
    end

    def resolve_target_person
      return target_person if target_person.present?

      Person.find(target_person_id)
    end

    def merge_memberships(source, target)
      source.memberships.update_all(person_id: target.id)
    end

    def merge_payments(source, target)
      source.payments.update_all(person_id: target.id)
    end

    def merge_subscriptions(source, target)
      source.book_of_entries.update_all(person_id: target.id)
    end

    def merge_newsletter(source, target)
      return unless source.newsletter_subscriber.present?

      subscriber = source.newsletter_subscriber
      subscriber.update!(person: target)
    end

    def merge_attributes(source, target)
      return unless target.email.blank?

      target.update!(email: source.email)
    end

    def instrument_success(source, target)
      ActiveSupport::Notifications.instrument(
        "people.account_merged",
        source_person_id: source.id,
        target_person_id: target.id,
        actor_id: actor_id,
        merge_type: merge_type
      )
    end

    def success(source_person:, target_person:)
      Result.new(success?: true, source_person: source_person, target_person: target_person, errors: [], message: "Accounts merged successfully")
    end

    def failure(message, errors = nil)
      Result.new(success?: false, source_person: nil, target_person: nil, errors: Array(errors || message), message: message)
    end
  end
end
