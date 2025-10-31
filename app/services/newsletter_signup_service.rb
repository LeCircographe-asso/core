class NewsletterSignupService
  def initialize(email, current_user = nil)
    @current_user = current_user
    # Normalize email by trimming whitespace and converting to lowercase
    @new_email = email.to_s.strip.downcase
    @person = Person.find_by(email: @new_email)
    @user = User.find_by(email_address: @new_email)
  end

  def call_newsletter
    subscriber = NewsletterSubscriber.find_by(email: @new_email)
    
    if subscriber
      handle_existing_subscriber(subscriber)
    else
      create_new_subscriber
    end
  end

  private

  def handle_existing_subscriber(subscriber)
    if subscriber.subscribed?
      { success: false, message: "Cette adresse email est déjà inscrite à la newsletter." }
    else
      subscriber.resubscribe!
      { success: true, message: "Vous êtes de nouveau inscrit à la newsletter." }
    end
  end

  def create_new_subscriber
    subscriber = NewsletterSubscriber.new(
      email: @new_email,
      subscribed: true,
      source: @current_user ? 'authenticated' : 'web'
    )
    
    # Link vers Person si existe
    person = Person.find_by(email: @new_email)
    subscriber.person = person if person
    
    if subscriber.save
      # Sync Person.newsletter_subscribed si lié
      person&.update(newsletter_subscribed: true)
      { success: true, message: "Inscription à la newsletter réussie !" }
    else
      { success: false, message: "Une erreur s'est produite. Veuillez réessayer." }
    end
  end

end
