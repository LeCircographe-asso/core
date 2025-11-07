module MembershipManagement
  class MembershipCreator < BaseService

    attribute :person
    attribute :membership_type_id, :integer
    attribute :payment_method, :string, default: "cash"
    attribute :recorded_by_id, :integer
    attribute :custom_amount_cents, :integer
    attribute :offer_reason, :string

    validates :person, presence: true
    validates :membership_type_id, presence: true
    validates :payment_method, presence: true
    validates :recorded_by_id, presence: true

    def call
      return failure("Invalid data: #{errors.full_messages.join(', ')}") unless valid?

      begin
        membership_type = MembershipType.find(membership_type_id)
        recorded_by = User.find(recorded_by_id)

        # Déléguer vers la logique existante dans Person
        result = person.create_membership!(
          membership_type,
          payment_method: payment_method.to_sym,
          recorded_by: recorded_by,
          custom_amount_cents: custom_amount_cents,
          offer_reason: offer_reason
        )

        # Instrumentation pour audit
        ActiveSupport::Notifications.instrument(
          "membership.created",
          person_id: person.id,
          membership_id: result[:membership].id,
          membership_type: membership_type.name,
          payment_method: payment_method,
          recorded_by_id: recorded_by_id,
          amount_cents: result[:payment].total_cents
        )

        success(membership: result[:membership], payment: result[:payment], message: "Membership created successfully")
      rescue ActiveRecord::RecordNotFound => e
        failure("Record not found: #{e.message}")
      rescue => e
        Rails.logger.error "[MembershipCreator] Error: #{e.message}"
        failure("Error creating membership: #{e.message}")
      end
    end

    private

    # success et failure hérités de BaseService
  end
end
