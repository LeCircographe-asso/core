module NewsletterManagement
  class NewsletterUpdater < BaseService
    attribute :person_id, :integer
    attribute :email, :string
    attribute :subscribed, :boolean
    attribute :source, :string, default: "admin"
    attribute :updated_by_id, :integer

    validates :updated_by_id, presence: true
    validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, if: -> { email.present? }

    def call
      return failure("Invalid data: #{errors.full_messages.join(', ')}") unless valid?

      begin
        updated_by = User.find(updated_by_id)

        # Vérifier les permissions
        unless updated_by.super_admin? || updated_by.admin? || updated_by.id == person&.user_id
          return failure("Insufficient permissions to update newsletter subscription")
        end

        # Trouver ou créer le subscriber
        subscriber = NewsletterSubscriber.find_or_initialize_by(email: email || person.email)

        # Mettre à jour le subscriber
        subscriber.assign_attributes(
          person: person,
          source: source,
          subscribed: subscribed
        )

        if subscribed
          subscriber.subscribed_at ||= Time.current
          subscriber.unsubscribed_at = nil
        else
          subscriber.unsubscribed_at ||= Time.current
        end

        subscriber.save!

        # Instrumentation pour audit
        ActiveSupport::Notifications.instrument(
          "newsletter.updated",
          newsletter_subscriber_id: subscriber.id,
          person_id: person_id,
          email: subscriber.email,
          subscribed: subscribed,
          updated_by_id: updated_by_id,
          source: source
        )

          success(subscriber: subscriber, message: "Newsletter subscription updated successfully")
      rescue ActiveRecord::RecordNotFound => e
        failure("User or Person not found: #{e.message}")
      rescue => e
        Rails.logger.error "[NewsletterUpdater] Error: #{e.message}"
        failure("Error updating newsletter subscription: #{e.message}")
      end
    end

    private

    def person
      @person ||= Person.find(person_id) if person_id.present?
    end

    # success et failure hérités de BaseService
  end
end
