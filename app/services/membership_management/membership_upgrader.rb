require "ostruct"

module MembershipManagement
  class MembershipUpgrader
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :person
    attribute :new_membership_type_id, :integer
    attribute :payment_method, :string, default: "cash"
    attribute :recorded_by_id, :integer
    attribute :custom_amount_cents, :integer
    attribute :offer_reason, :string

    validates :person, presence: true
    validates :new_membership_type_id, presence: true
    validates :payment_method, presence: true
    validates :recorded_by_id, presence: true

    def call
      return failure("Invalid data: #{errors.full_messages.join(', ')}") unless valid?

      begin
        new_membership_type = MembershipType.find(new_membership_type_id)
        recorded_by = User.find(recorded_by_id)

        # Déléguer vers la logique existante dans Person
        result = person.upgrade_membership!(
          new_membership_type,
          payment_method: payment_method.to_sym,
          recorded_by: recorded_by,
          custom_amount_cents: custom_amount_cents,
          offer_reason: offer_reason
        )

        # Instrumentation pour audit
        ActiveSupport::Notifications.instrument(
          "membership.upgraded",
          person_id: person.id,
          old_membership_id: person.current_membership&.id,
          new_membership_id: result[:membership].id,
          new_membership_type: new_membership_type.name,
          payment_method: payment_method,
          recorded_by_id: recorded_by_id,
          amount_cents: result[:payment]&.total_cents || 0,
          member_number_changed: result[:member_number_changed],
          old_member_number: result[:old_member_number],
          new_member_number: result[:new_member_number]
        )

        success(result[:membership], result[:payment], result)
      rescue ActiveRecord::RecordNotFound => e
        failure("Record not found: #{e.message}")
      rescue => e
        Rails.logger.error "[MembershipUpgrader] Error: #{e.message}"
        failure("Error upgrading membership: #{e.message}")
      end
    end

    private

    def success(membership, payment, full_result)
      OpenStruct.new(
        success?: true,
        membership: membership,
        payment: payment,
        member_number_changed: full_result[:member_number_changed],
        old_member_number: full_result[:old_member_number],
        new_member_number: full_result[:new_member_number],
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
