require "ostruct"

module People
  class NewsletterSignup
    include ActiveModel::Model
    include ActiveModel::Attributes

    Result = Struct.new(:success?, :message, :redirect_to, keyword_init: true)

    attribute :email, :string
    attribute :source, :string, default: "web"

    validates :email, presence: true

    def call
      return failure("Veuillez entrer une adresse email valide.") unless valid?

      normalized_email = email.to_s.strip.downcase
      person = Person.find_by(email: normalized_email)
      existing = NewsletterSubscriber.find_by(email: normalized_email)

      if existing
        ActiveSupport::Notifications.instrument(
          "people.newsletter_signup.skipped",
          email: normalized_email, reason: "already_subscribed", person_id: existing.person_id, source: source
        )
        return Result.new(success?: false, message: "Cette adresse est déjà dans notre liste. Connectez-vous pour gérer votre inscription.", redirect_to: true)
      end

      subscriber = NewsletterSubscriber.new(
        email: normalized_email,
        subscribed: true,
        source: source
      )
      subscriber.person = person if person

      if subscriber.save
        ActiveSupport::Notifications.instrument(
          "people.newsletter_signed_up",
          email: normalized_email, person_id: subscriber.person_id, subscriber_id: subscriber.id, source: source
        )
        success("Inscription à la newsletter réussie !")
      else
        ActiveSupport::Notifications.instrument(
          "people.newsletter_signup.failed",
          email: normalized_email, errors: subscriber.errors.full_messages, source: source
        )
        failure("Une erreur s'est produite. Veuillez réessayer.")
      end
    end

    private

    def success(message)
      Result.new(success?: true, message: message, redirect_to: false)
    end

    def failure(message)
      Result.new(success?: false, message: message, redirect_to: false)
    end
  end
end
