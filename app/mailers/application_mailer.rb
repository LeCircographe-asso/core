class ApplicationMailer < ActionMailer::Base
  default from: "no-reply@lecircographe.fr"
  layout "mailer"

  private

  # Set unsubscribe URL for newsletter emails
  def set_unsubscribe_url
    if @user&.email.present?
      subscriber = NewsletterSubscriber.find_by(email: @user.email)
      @unsubscribe_url = newsletter_unsubscribe_url(subscriber.unsubscribe_token) if subscriber&.unsubscribe_token
    end
  end
end
