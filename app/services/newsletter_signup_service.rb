class NewsletterSignupService
  def initialize(email)
    # Normalize email by trimming whitespace and converting to lowercase
    @new_email = email.to_s.strip.downcase
    @person = Person.find_by(email: @new_email)
    @user = User.find_by(email_address: @new_email)
  end

  # Public newsletter subscription ONLY (from footer/forms)
  # No toggle/unsubscribe - that's done via settings/profile
  def call_newsletter
    subscriber = NewsletterSubscriber.find_by(email: @new_email)

    if subscriber
      # If email already exists, redirect to login for management
      { success: false, message: "Cette adresse est déjà dans notre liste. Connectez-vous pour gérer votre inscription.", redirect_to: true }
    else
      create_new_subscriber
    end
  end


  private

  def create_new_subscriber
    subscriber = NewsletterSubscriber.new(
      email: @new_email,
      subscribed: true,
      source: "web"
    )

    # Link vers Person si existe
    subscriber.person = @person if @person

    if subscriber.save
      { success: true, message: "Inscription à la newsletter réussie !" }
    else
      { success: false, message: "Une erreur s'est produite. Veuillez réessayer." }
    end
  end
end
