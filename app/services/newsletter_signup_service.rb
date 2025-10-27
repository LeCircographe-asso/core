class NewsletterSignupService
  def initialize(email, current_user = nil)
    @current_user = current_user
    # Normalize email by trimming whitespace and converting to lowercase
    @new_email = email.to_s.strip.downcase
    @person = Person.find_by(email: @new_email)
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
    # Vérifier si l'email correspond à la Person de l'utilisateur connecté
    if @current_user.person&.email&.downcase == @new_email
      if @current_user.person.newsletter_subscribed
        { success: false, message: "Vous êtes déjà inscrit à la newsletter." }
      else
        @current_user.person.update!(newsletter_subscribed: true)
        # Generate unsubscribe token if not already present
        ensure_unsubscribe_token(@current_user)
        { success: true, message: "Vous êtes maintenant inscrit à la newsletter." }
      end
    elsif @current_user.email_address.downcase == @new_email
      # Fallback pour les anciens comptes sans Person liée
      if @current_user.newsletter_subscribed
        { success: false, message: "Vous êtes déjà inscrit à la newsletter." }
      else
        @current_user.update(newsletter_subscribed: true)
        ensure_unsubscribe_token(@current_user)
        { success: true, message: "Vous êtes maintenant inscrit à la newsletter." }
      end
    else
      { success: false, message: "Vous ne pouvez pas inscrire une autre adresse email à la newsletter." }
    end
  end

  def handle_guest_user
    # Chercher d'abord par Person.email (priorité)
    if @person
      if @person.newsletter_subscribed
        { success: false, message: "Cette adresse email est déjà inscrite à la newsletter." }
      else
        { success: false, message: "Cette adresse email existe déjà. Veuillez vous connecter pour modifier vos préférences." }
      end
    elsif @user
      # Si c'est un User sans Person liée, c'est un problème d'architecture
      # On ne peut pas inscrire à la newsletter avec un email de connexion seul
      { success: false, message: "Cette adresse email est utilisée pour la connexion. Veuillez utiliser votre email de newsletter." }
    else
      # Créer une Person uniquement pour la newsletter
      create_newsletter_only_person
    end
  end

  # Ensure user has an unsubscribe token
  def ensure_unsubscribe_token(user)
    return if user.unsubscribe_token.present?

    user.update(unsubscribe_token: SecureRandom.urlsafe_base64(32))
  end

  # Create a Person only for newsletter subscription
  def create_newsletter_only_person
    # Vérifier l'unicité de l'email
    if User.where(email_address: @new_email).where(person_id: nil).exists?
      return { success: false, message: "Cette adresse email est déjà utilisée par un compte de connexion existant" }
    end

    # Créer une Person uniquement pour la newsletter
    person = Person.new(
      first_name: "Newsletter",
      last_name: "Subscriber",
      email: @new_email,
      newsletter_subscribed: true
    )

    # Skip validation d'adhésion pour newsletter seule
    person.skip_membership_validation = true

    if person.save
      { success: true, message: "Inscription à la newsletter réussie !" }
    else
      { success: false, message: "Une erreur s'est produite lors de l'inscription. Veuillez réessayer." }
    end
  rescue ActiveRecord::RecordInvalid => e
    { success: false, message: e.message }
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
