require "ostruct"

module Memberships
  class Upgrade
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :person_id, :integer
    attribute :new_membership_type_id, :integer
    attribute :started_at, :date
    attribute :payment_method, :string

    validates :person_id, presence: true
    validates :new_membership_type_id, presence: true

    def initialize(membership = nil, new_membership_type = nil, custom_start_date = nil)
      super()
      @membership = membership
      @new_membership_type = new_membership_type
      @custom_start_date = custom_start_date
    end

    def call
      return failure("Membership is required") unless @membership
      return failure("New membership type is required") unless @new_membership_type
      return failure("Cannot upgrade to the same membership type") unless upgrade_allowed?

      ActiveRecord::Base.transaction do
        perform_upgrade
        success
      end
    rescue StandardError => e
      failure(e.message)
    end

    private

    def upgrade_allowed?
      return false if @membership.membership_type == @new_membership_type
      return false if @membership.membership_type.circus? && @new_membership_type.basic?
      true
    end

    def perform_upgrade
      start_date = @custom_start_date || Date.current
      @membership.upgrade_to!(@new_membership_type, start_date)
    end

    def success
      OpenStruct.new(
        success?: true,
        new_membership: @membership.person.reload.current_membership,
        old_membership: @membership,
        message: "Membership upgraded successfully"
      )
    end

    def failure(message)
      OpenStruct.new(
        success?: false,
        errors: [ message ],
        message: message
      )
    end
  end
end
