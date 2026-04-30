# frozen_string_literal: true

require "ostruct"

module People
  class MembershipCreator
    include ActiveModel::Model
    include ActiveModel::Attributes

    Result = Struct.new(:success?, :membership, :payment, :errors, :message, :already_existed, keyword_init: true)

    attribute :person
    attribute :membership_type_id, :integer
    attribute :payment_method, :string, default: "cash"
    attribute :recorded_by_id, :integer
    attribute :custom_amount_cents, :integer
    attribute :offer_reason, :string
    attribute :donation_cents, :integer

    validates :person, presence: true
    validates :membership_type_id, presence: true
    validates :payment_method, inclusion: { in: %w[cash card cheque transfer offered] }

    def call
      return failure("Invalid data", errors.full_messages) unless valid?

      if person.memberships.active.current.exists?
        ActiveSupport::Notifications.instrument(
          "membership.skipped",
          person_id: person.id, reason: "already_active", membership_type_id: membership_type_id
        )
        return Result.new(success?: true, membership: person.memberships.active.current.first, payment: nil, errors: [], message: "Person already has an active membership", already_existed: true)
      end

      membership_type = MembershipType.find(membership_type_id)
      recorded_by = find_recorded_by

      membership_data = person.create_membership!(
        membership_type,
        payment_method: payment_method.to_sym,
        recorded_by: recorded_by,
        custom_amount_cents: custom_amount_cents,
        offer_reason: offer_reason,
        donation_cents: donation_cents
      )

      ActiveSupport::Notifications.instrument(
        "membership.created",
        person_id: person.id, membership_id: membership_data[:membership].id, payment_id: membership_data[:payment].id,
        membership_type_id: membership_type.id, payment_method: payment_method
      )

      Result.new(
        success?: true,
        membership: membership_data[:membership],
        payment: membership_data[:payment],
        errors: [],
        message: "Membership created successfully",
        already_existed: false
      )
    rescue ActiveRecord::RecordNotFound => e
      ActiveSupport::Notifications.instrument("membership.failed", error: e.message, reason: "record_not_found")
      failure("Record not found: #{e.message}")
    rescue ActiveRecord::RecordInvalid => e
      ActiveSupport::Notifications.instrument("membership.failed", error: e.message, reason: "validation")
      failure("Validation error: #{e.message}")
    rescue StandardError => e
      db_path = ActiveRecord::Base.connection_db_config&.database
      Rails.logger.error("[People::MembershipCreator] db=#{db_path} #{e.class}: #{e.message}\n#{e.backtrace.take(5).join("\n")}")
      ActiveSupport::Notifications.instrument("membership.failed", error: e.message, reason: "exception")
      failure("Error creating membership: #{e.message}")
    end

    private

    def find_recorded_by
      return @recorded_by if defined?(@recorded_by)

      if recorded_by_id.present?
        @recorded_by = User.find(recorded_by_id)
      elsif Current.respond_to?(:user) && Current.user.present?
        @recorded_by = Current.user
      else
        raise "A recorded_by user is required to create a membership"
      end
    end

    def failure(message, error_list = nil)
      Result.new(
        success?: false,
        membership: nil,
        payment: nil,
        errors: Array(error_list || message),
        message: message,
        already_existed: false
      )
    end
  end
end
