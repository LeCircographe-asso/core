# frozen_string_literal: true

module MembershipTypeManagement
  class MembershipTypeCreator < BaseService
    attribute :name, :string
    attribute :category, :string
    attribute :price_cents, :integer
    attribute :description, :string
    attribute :effective_from, :date
    attribute :version, :integer
    attribute :created_by_user_id, :integer

    validates :name, presence: true
    validates :category, presence: true, inclusion: { in: %w[basic circus event] }
    validates :price_cents, presence: true, numericality: { greater_than: 0 }
    validates :created_by_user_id, presence: true
    validates :effective_from, presence: true

    def call
      return failure(I18n.t("services.validation.invalid_data_with_details", details: errors.full_messages.join(", "))) unless valid?

      begin
        created_by = User.find(created_by_user_id)

        # Vérifier les permissions
        return failure("Insufficient permissions to create membership type") unless created_by.super_admin? || created_by.admin?

        membership_type = MembershipType.create!(
          name: name,
          category: category,
          price_cents: price_cents,
          description: description,
          effective_from: effective_from || Date.current,
          version: version || 1,
          created_by_user: created_by
        )

        # Instrumentation pour audit
        ActiveSupport::Notifications.instrument(
          "membership_type.created",
          membership_type_id: membership_type.id,
          name: name,
          category: category,
          price_cents: price_cents,
          created_by_id: created_by_user_id
        )

        success(membership_type: membership_type, message: "Membership type created successfully")
      rescue ActiveRecord::RecordNotFound => e
        failure("User not found: #{e.message}")
      rescue StandardError => e
        Rails.logger.error "[MembershipTypeCreator] Error: #{e.message}"
        failure("Error creating membership type: #{e.message}")
      end
    end

    # success et failure hérités de BaseService
  end
end
