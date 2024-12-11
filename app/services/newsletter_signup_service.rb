class NewsletterSignupService
  def initialize(email, current_user = nil)
    @current_user = current_user
    @user = User.find_by(email_address: email)
    @new_email = email
  end

  def call_newsletter
    if @current_user
      handle_authenticated_user
    else
      handle_guest_user
    end
  end

  private

  def handle_authenticated_user
    if @current_user.email_address == @new_email
      if @current_user.newsletter
        { success: false, message: "Vous êtes déjà inscrit à la newsletter." }
      else
        @current_user.update(newsletter: true)
        { success: true, message: "Vous êtes maintenant inscrit à la newsletter." }
      end
    else
      { success: false, message: "Vous ne pouvez pas inscrire une autre adresse email à la newsletter." }
    end
  end

  def handle_guest_user
    if @user
      if @user.newsletter
        { success: false, message: "Cet utilisateur est déjà inscrit à la newsletter." }
      else
        { success: false, message: "Cet email existe déjà. Veuillez vous connecter pour modifier vos préférences." }
      end
    else
      create_user_and_subscribe
    end
  end

  def create_user_and_subscribe
    random_password = SecureRandom.hex(12)
    new_user = User.new(
      email_address: @new_email,
      password_digest: BCrypt::Password.create(random_password),
      newsletter: true
    )

    if new_user.save
      { success: true, message: "Un compte a été créé et vous êtes inscrit à la newsletter." }
    else
      { success: false, message: "Une erreur s'est produite lors de l'inscription. Veuillez réessayer." }
    end
  end
end
