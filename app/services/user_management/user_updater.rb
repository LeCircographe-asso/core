# frozen_string_literal: true

module UserManagement
  class UserUpdater < BaseService
    attribute :user_id, :integer
    attribute :email_address, :string
    attribute :system_role, :string
    attribute :person_attributes, hash: true
    attribute :newsletter_subscribed, :boolean
    attribute :updated_by_id, :integer

    validates :user_id, presence: true
    validates :updated_by_id, presence: true

    def call
      return failure(I18n.t("services.validation.invalid_data_with_details", details: errors.full_messages.join(", "))) unless valid?

      begin
        user = User.find(user_id)
        updated_by = User.find(updated_by_id)

        # Vérifier les permissions
        return failure("Insufficient permissions to update this user") unless can_update_user?(user, updated_by)

        ActiveRecord::Base.transaction do
          # Mettre à jour User (seulement si des attributs sont fournis)
          user_attrs = {}
          user_attrs[:email_address] = email_address if email_address.present?
          user_attrs[:system_role] = system_role if system_role.present?

          user_updated = user_attrs.empty? || user.update(user_attrs)

          # Mettre à jour Person si présente
          person_updated = true
          if user.person.present? && person_attributes.present?
            user.person.skip_membership_validation = true
            person_updated = user.person.update(person_attributes.except(:newsletter_subscribed))
          end

          # Gérer newsletter si nécessaire
          if person_updated && user.person.present? && !newsletter_subscribed.nil?
            newsletter_result = update_newsletter(user.person)
            return failure("Error updating newsletter: #{newsletter_result.message}") unless newsletter_result.success?
          end

          if user_updated && person_updated
            # Instrumentation pour audit
            ActiveSupport::Notifications.instrument(
              "user.updated",
              user_id: user.id,
              person_id: user.person&.id,
              updated_by_id: updated_by_id,
              changes: user.previous_changes.merge(user.person&.previous_changes || {})
            )

            success(user: user, person: user.person, message: "User updated successfully")
          else
            errors_array = []
            errors_array.concat(user.errors.full_messages) if user.errors.any?
            errors_array.concat(user.person.errors.full_messages) if user.person&.errors&.any?
            failure("Validation errors: #{errors_array.join(', ')}")
          end
        end
      rescue ActiveRecord::RecordNotFound => e
        failure("User not found: #{e.message}")
      rescue StandardError => e
        Rails.logger.error "[UserUpdater] Error: #{e.message}"
        failure("Error updating user: #{e.message}")
      end
    end

    private

    def can_update_user?(user, updated_by)
      # Un utilisateur peut mettre à jour son propre compte
      return true if updated_by.id == user.id

      # Un admin/super_admin peut mettre à jour n'importe quel compte
      updated_by.super_admin? || updated_by.admin?
    end

    def update_newsletter(person)
      return success(message: "Newsletter update skipped (no email)") if person.email.blank?

      updater = NewsletterManagement::NewsletterUpdater.new(
        person_id: person.id,
        email: person.email,
        subscribed: newsletter_subscribed,
        source: "authenticated",
        updated_by_id: updated_by_id
      )

      updater.call
    end

    # success et failure hérités de BaseService
  end
end
