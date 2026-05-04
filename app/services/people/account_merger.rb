# frozen_string_literal: true

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
      return failure(I18n.t("services.validation.invalid_data_with_details", details: errors.full_messages.join(", "))) unless valid?

      source = resolve_source_person
      target = resolve_target_person

      return failure("Source and target persons are identical") if source == target

      ActiveRecord::Base.transaction do
        merge_memberships(source, target)
        merge_payments(source, target)
        merge_contributions(source, target)
        merge_attendances(source, target)
        merge_newsletter(source, target)
        merge_account_claims(source, target)
        merge_member_number_histories(source, target)
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
    rescue StandardError => e
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
      transfer_relation(source.memberships, target.id)
    end

    def merge_payments(source, target)
      transfer_relation(source.payments, target.id)
    end

    def merge_contributions(source, target)
      transfer_relation(source.contributions, target.id)
    end

    def merge_attendances(source, target)
      transfer_relation(source.attendances, target.id)
    end

    def merge_newsletter(source, target)
      return if source.newsletter_subscriber.blank?

      subscriber = source.newsletter_subscriber
      subscriber.update!(person: target)
    end

    def merge_account_claims(source, target)
      transfer_relation(source.account_claims, target.id)
    end

    def merge_member_number_histories(source, target)
      transfer_relation(source.member_number_histories, target.id)
    end

    def merge_attributes(source, target)
      attrs = {}
      if source.email.present? && (target.email.blank? || target_email_is_auth_placeholder?(target))
        source_email = source.email
        # When we intend to destroy source, free unique email first.
        # rubocop:disable Rails/SkipsModelValidations
        source.update_column(:email, nil) if destroy_source
        # rubocop:enable Rails/SkipsModelValidations
        attrs[:email] = source_email
      end
      attrs[:first_name] = source.first_name if should_replace_identity_value?(target.first_name) && source.first_name.present?
      attrs[:last_name] = source.last_name if should_replace_identity_value?(target.last_name) && source.last_name.present?
      return if attrs.empty?

      target.update!(attrs)
    end

    def should_replace_identity_value?(value)
      value.blank? || value.in?(%w[Web User])
    end

    def target_email_is_auth_placeholder?(target)
      target.user.present? && target.email.present? && target.email.casecmp?(target.user.email_address.to_s)
    end

    # Intentional batch reassignment for large merges.
    # This runs inside a transaction and avoids callback storms.
    def transfer_relation(relation_scope, target_person_id)
      # rubocop:disable Rails/SkipsModelValidations
      relation_scope.update_all(person_id: target_person_id)
      # rubocop:enable Rails/SkipsModelValidations
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
