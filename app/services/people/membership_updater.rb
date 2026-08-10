# frozen_string_literal: true

require "ostruct"

module People
  class MembershipUpdater
    include ActiveModel::Model
    include ActiveModel::Attributes

    Result = Struct.new(:success?, :membership, :errors, :message, keyword_init: true)

    attr_accessor :membership

    attribute :membership_id, :integer
    attribute :membership_type_id, :integer
    attribute :started_at, :date
    attribute :ended_at, :date
    attribute :updated_by_id, :integer

    validates :membership_type_id, presence: true
    validate :membership_presence

    def call
      return failure(I18n.t("services.validation.invalid_data"), errors.full_messages) unless valid?

      target_membership = membership || Membership.find(membership_id)
      membership_type = MembershipType.find(membership_type_id)
      user = resolve_user

      return failure(I18n.t("services.errors.insufficient_permissions.membership_update")) unless can_update?(user)

      ActiveRecord::Base.transaction do
        target_membership.update!(
          membership_type: membership_type,
          started_at: started_at || target_membership.started_at,
          ended_at: ended_at || target_membership.ended_at
        )

        Result.new(
          success?: true,
          membership: target_membership,
          errors: [],
          message: I18n.t("services.success.membership_updated")
        )
      end
    rescue ActiveRecord::RecordNotFound => e
      failure(I18n.t("services.errors.record_not_found", message: e.message))
    rescue ActiveRecord::RecordInvalid => e
      failure(I18n.t("services.errors.validation_error", message: e.message))
    rescue StandardError => e
      Rails.logger.error("[People::MembershipUpdater] #{e.class}: #{e.message}\n#{e.backtrace.take(5).join("\n")}")
      failure(I18n.t("services.errors.unexpected_error", action: "membership update", message: e.message))
    end

    private

    def resolve_user
      return @user if defined?(@user)

      if updated_by_id.present?
        @user = User.find(updated_by_id)
      elsif Current.respond_to?(:user) && Current.user.present?
        @user = Current.user
      else
        raise "An updated_by user is required to update a membership"
      end
    end

    def can_update?(user)
      user.can_administer?
    end

    def membership_presence
      errors.add(:membership_id, "must be provided") if membership.nil? && membership_id.blank?
    end

    def failure(message, error_list = nil)
      Result.new(
        success?: false,
        membership: nil,
        errors: Array(error_list || message),
        message: message
      )
    end
  end
end
