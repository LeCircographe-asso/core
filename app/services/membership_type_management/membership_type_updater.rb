# frozen_string_literal: true

module MembershipTypeManagement
  class MembershipTypeUpdater < BaseService
    attribute :membership_type_id, :integer
    attribute :name, :string
    attribute :category, :string
    attribute :price_cents, :integer
    attribute :description, :string
    attribute :effective_from, :date
    attribute :updated_by_id, :integer

    validates :membership_type_id, presence: true
    validates :updated_by_id, presence: true

    def call
      return failure("Invalid data: #{errors.full_messages.join(', ')}") unless valid?

      begin
        membership_type = MembershipType.find(membership_type_id)
        updated_by = User.find(updated_by_id)

        # Vérifier les permissions
        return failure('Insufficient permissions to update membership type') unless updated_by.super_admin? || updated_by.admin?

        # Mettre à jour uniquement les champs fournis
        update_attrs = {}
        update_attrs[:name] = name if name.present?
        update_attrs[:category] = category if category.present?
        update_attrs[:price_cents] = price_cents if price_cents.present?
        update_attrs[:description] = description if description.present?
        update_attrs[:effective_from] = effective_from if effective_from.present?

        membership_type.update!(update_attrs)

        # Instrumentation pour audit
        ActiveSupport::Notifications.instrument(
          'membership_type.updated',
          membership_type_id: membership_type.id,
          updated_by_id: updated_by_id,
          changes: membership_type.previous_changes
        )

        success(membership_type: membership_type, message: 'Membership type updated successfully')
      rescue ActiveRecord::RecordNotFound => e
        failure("MembershipType or User not found: #{e.message}")
      rescue StandardError => e
        Rails.logger.error "[MembershipTypeUpdater] Error: #{e.message}"
        failure("Error updating membership type: #{e.message}")
      end
    end

    # success et failure hérités de BaseService
  end
end
