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
        return failure(I18n.t("services.errors.insufficient_permissions.user_update")) unless can_update_user?(user, updated_by)

        ActiveRecord::Base.transaction do
          # Mettre à jour User (seulement si des attributs sont fournis)
          user_attrs = {}
          user_attrs[:email_address] = email_address if email_address.present?
          user_attrs[:system_role] = system_role if system_role.present?

          user_updated = user_attrs.empty? || user.update(user_attrs)

          # Mettre à jour Person si présente (tester person_attributes en premier pour éviter un load Person inutile)
          person_updated = true
          if person_attributes.present? && user.person.present?
            user.person.skip_membership_validation = true
            person_updated = user.person.update(person_attributes.except(:newsletter_subscribed))
          end

          # Gérer newsletter si nécessaire (nil d'abord pour ne pas charger Person quand la clé était absente de la requête)
          if person_updated && !newsletter_subscribed.nil? && user.person.present?
            newsletter_result = update_newsletter(user.person)
            return failure(I18n.t("services.errors.newsletter_update_failed", message: newsletter_result.message)) unless newsletter_result.success?
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

            success(user: user, person: user.person, message: I18n.t("services.success.user_updated"))
          else
            errors_array = []
            errors_array.concat(user.errors.full_messages) if user.errors.any?
            errors_array.concat(user.person.errors.full_messages) if user.person&.errors&.any?
            failure(I18n.t("services.validation.invalid_data_with_details", details: errors_array.join(", ")))
          end
        end
      rescue ActiveRecord::RecordNotFound => e
        failure(I18n.t("services.errors.user_not_found", message: e.message))
      rescue StandardError => e
        Rails.logger.error "[UserUpdater] Error: #{e.message}"
        failure(I18n.t("services.errors.unexpected_error", action: "user update", message: e.message))
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
      return success(message: I18n.t("services.success.newsletter_update_skipped_no_email")) if person.email.blank?

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
