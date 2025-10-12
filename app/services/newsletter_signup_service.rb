class NewsletterSignupService
  def initialize(email, current_user = nil)
    @current_user = current_user
    # Normalize email by trimming whitespace and converting to lowercase
    @new_email = email.to_s.strip.downcase
    @user = User.find_by(email_address: @new_email)
  end

  def call_newsletter
    # Record the attempt for analytics/rate limiting
    log_newsletter_attempt

    # Handle based on authentication state
    if @current_user
      handle_authenticated_user
    else
      handle_guest_user
    end
  end

  private

  def handle_authenticated_user
    if @current_user.email_address.downcase == @new_email
      if @current_user.newsletter_subscribed
        { success: false, message: "Vous êtes déjà inscrit à la newsletter." }
      else
        @current_user.update(newsletter_subscribed: true)
        # Generate unsubscribe token if not already present
        ensure_unsubscribe_token(@current_user)
        { success: true, message: "Vous êtes maintenant inscrit à la newsletter." }
      end
    else
      { success: false, message: "Vous ne pouvez pas inscrire une autre adresse email à la newsletter." }
    end
  end

  def handle_guest_user
    if @user
      if @user.newsletter_subscribed
        { success: false, message: "Cette adresse email est déjà inscrite à la newsletter." }
      else
        { success: false, message: "Cette adresse email existe déjà. Veuillez vous connecter pour modifier vos préférences." }
      end
    else
      { success: false, message: "Veuillez créer un compte pour vous inscrire à la newsletter.", redirect_to: true }
    end
  end

  # Ensure user has an unsubscribe token
  def ensure_unsubscribe_token(user)
    return if user.unsubscribe_token.present?

    user.update(unsubscribe_token: SecureRandom.urlsafe_base64(32))
  end

  # Log the newsletter signup attempt (useful for rate limiting and analytics)
  def log_newsletter_attempt
    # This could be expanded to log to a database or monitoring system
    Rails.logger.info("Newsletter signup attempt for: #{@new_email}")
  end

  # Not currently used - would require policy updates
  def create_user_and_subscribe
    random_password = SecureRandom.hex(12)
    new_user = User.new(
      email_address: @new_email,
      password_digest: BCrypt::Password.create(random_password),
      newsletter_subscribed: true,
      unsubscribe_token: SecureRandom.urlsafe_base64(32)
    )

    if new_user.save
      { success: true, message: "Un compte a été créé et vous êtes inscrit à la newsletter." }
    else
      { success: false, message: "Une erreur s'est produite lors de l'inscription. Veuillez réessayer." }
    end
  end
end
