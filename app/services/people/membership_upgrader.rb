# frozen_string_literal: true

require "ostruct"

module People
  class MembershipUpgrader
    include ActiveModel::Model
    include ActiveModel::Attributes

    Result = Struct.new(:success?, :membership, :payment, :member_number_changed, :old_member_number, :new_member_number, :errors, :message, keyword_init: true)

    attribute :person
    attribute :new_membership_type_id, :integer
    attribute :payment_method, :string, default: "cash"
    attribute :recorded_by_id, :integer
    attribute :custom_amount_cents, :integer
    attribute :offer_reason, :string
    attribute :donation_cents, :integer

    validates :person, presence: true
    validates :new_membership_type_id, presence: true
    validates :payment_method, inclusion: { in: %w[cash card cheque transfer offered] }

    def call
      return failure(I18n.t("services.validation.invalid_data"), errors.full_messages) unless valid?

      new_membership_type = MembershipType.find(new_membership_type_id)
      recorded_by = resolve_recorded_by

      result = person.upgrade_membership!(
        new_membership_type,
        payment_method: payment_method.to_sym,
        recorded_by: recorded_by,
        custom_amount_cents: custom_amount_cents,
        offer_reason: offer_reason,
        donation_cents: donation_cents
      )

      ActiveSupport::Notifications.instrument(
        "membership.upgraded",
        person_id: person.id, old_member_number: result[:old_member_number], new_member_number: result[:new_member_number],
        membership_id: result[:membership].id, payment_id: result[:payment].id, new_membership_type_id: new_membership_type.id,
        payment_method: payment_method
      )

      Result.new(
        success?: true,
        membership: result[:membership],
        payment: result[:payment],
        member_number_changed: result[:member_number_changed],
        old_member_number: result[:old_member_number],
        new_member_number: result[:new_member_number],
        errors: [],
        message: "Membership upgraded successfully"
      )
    rescue ActiveRecord::RecordNotFound => e
      ActiveSupport::Notifications.instrument("membership.upgrade_failed", error: e.message, reason: "record_not_found")
      failure("Record not found: #{e.message}")
    rescue StandardError => e
      Rails.logger.error("[People::MembershipUpgrader] #{e.class}: #{e.message}\n#{e.backtrace.take(5).join("\n")}")
      ActiveSupport::Notifications.instrument("membership.upgrade_failed", error: e.message, reason: "exception")
      failure("Error upgrading membership: #{e.message}")
    end

    private

    def resolve_recorded_by
      return @recorded_by if defined?(@recorded_by)

      if recorded_by_id.present?
        @recorded_by = User.find(recorded_by_id)
      elsif Current.respond_to?(:user) && Current.user.present?
        @recorded_by = Current.user
      else
        raise "A recorded_by user is required to upgrade a membership"
      end
    end

    def failure(message, error_list = nil)
      Result.new(
        success?: false,
        membership: nil,
        payment: nil,
        member_number_changed: false,
        old_member_number: nil,
        new_member_number: nil,
        errors: Array(error_list || message),
        message: message
      )
    end
  end
end
