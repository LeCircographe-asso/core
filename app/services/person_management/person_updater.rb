module PersonManagement
  class PersonUpdater < BaseService

    attribute :person_id, :integer
    attribute :attributes, hash: true
    attribute :newsletter_subscribed, :boolean
    attribute :updated_by_id, :integer

    validates :person_id, presence: true
    validates :updated_by_id, presence: true

    def call
      return failure("Invalid data: #{errors.full_messages.join(', ')}") unless valid?

      begin
        person = Person.find(person_id)
        updated_by = User.find(updated_by_id)

        # Vérifier les permissions
        unless can_update_person?(person, updated_by)
          return failure("Insufficient permissions to update this person")
        end

        ActiveRecord::Base.transaction do
          # Mettre à jour Person
          person.skip_membership_validation = true
          person_updated = person.update(attributes.except(:newsletter_subscribed))

          # Gérer newsletter si nécessaire
          if person_updated && !newsletter_subscribed.nil?
            newsletter_result = update_newsletter(person)
            unless newsletter_result.success?
              return failure("Error updating newsletter: #{newsletter_result.message}")
            end
          end

          if person_updated
            # Instrumentation pour audit
            ActiveSupport::Notifications.instrument(
              "person.updated",
              person_id: person.id,
              updated_by_id: updated_by_id,
              changes: person.previous_changes
            )

            success(person: person, message: "Person updated successfully")
          else
            failure("Validation errors: #{person.errors.full_messages.join(', ')}")
          end
        end
      rescue ActiveRecord::RecordNotFound => e
        failure("Person or User not found: #{e.message}")
      rescue => e
        Rails.logger.error "[PersonUpdater] Error: #{e.message}"
        failure("Error updating person: #{e.message}")
      end
    end

    private

    def can_update_person?(person, updated_by)
      # Un utilisateur peut mettre à jour sa propre Person
      return true if updated_by.person&.id == person.id

      # Un admin/super_admin peut mettre à jour n'importe quelle Person
      updated_by.super_admin? || updated_by.admin?
    end

    def update_newsletter(person)
      return success(message: "Newsletter update skipped (no email)") if person.email.blank?

      updater = NewsletterManagement::NewsletterUpdater.new(
        person_id: person.id,
        email: person.email,
        subscribed: newsletter_subscribed,
        source: 'admin',
        updated_by_id: updated_by_id
      )

      updater.call
    end

    # success et failure hérités de BaseService
  end
end


