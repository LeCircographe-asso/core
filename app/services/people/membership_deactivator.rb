require 'ostruct'

module People
  class MembershipDeactivator
    include ActiveModel::Model
    include ActiveModel::Attributes

    Result = Struct.new(:success?, :membership, :errors, :message, keyword_init: true)

    attr_accessor :membership

    attribute :membership_id, :integer
    attribute :deactivated_by_id, :integer
    attribute :reason, :string

    validates :reason, presence: true
    validate :membership_presence

    def call
      return failure('Invalid data', errors.full_messages) unless valid?

      target_membership = membership || Membership.find(membership_id)
      user = resolve_user

      return failure('Insufficient permissions to deactivate this membership') unless can_deactivate?(user)

      ActiveRecord::Base.transaction do
        target_membership.update!(status: :inactive)

        Result.new(
          success?: true,
          membership: target_membership,
          errors: [],
          message: 'Membership deactivated successfully'
        )
      end
    rescue ActiveRecord::RecordNotFound => e
      failure("Record not found: #{e.message}")
    rescue ActiveRecord::RecordInvalid => e
      failure("Validation error: #{e.message}")
    rescue StandardError => e
      Rails.logger.error("[People::MembershipDeactivator] #{e.class}: #{e.message}\n#{e.backtrace.take(5).join("\n")}")
      failure("Error deactivating membership: #{e.message}")
    end

    private

    def resolve_user
      return @user if defined?(@user)

      if deactivated_by_id.present?
        @user = User.find(deactivated_by_id)
      elsif Current.respond_to?(:user) && Current.user.present?
        @user = Current.user
      else
        raise 'A deactivated_by user is required to deactivate a membership'
      end
    end

    def can_deactivate?(user)
      user.super_admin? || user.admin?
    end

    def membership_presence
      errors.add(:membership_id, 'must be provided') if membership.nil? && membership_id.blank?
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
