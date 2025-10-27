class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  def new
    if authenticated?
      redirect_to root_path
    end
    @user = User.new(email_address: session[:newsletter_email])
  end

  def create
    # Utiliser Web::UserRegistration pour créer un espace utilisateur
    result = Web::UserRegistration.new(
      first_name: user_params[:first_name].present? ? user_params[:first_name] : "Utilisateur",
      last_name: user_params[:last_name].present? ? user_params[:last_name] : "Anonyme",
      email: user_params[:email_address],
      newsletter_subscribed: user_params[:newsletter_subscribed] == "1",
      user_email: user_params[:email_address],
      user_password: user_params[:password],
      user_system_role: "web_visitor"
    ).call

    if result.success?
      UserMailer.welcome_email(result.user).deliver_later
      start_new_session_for result.user
      redirect_to root_path, notice: "Inscription réussie !"
    else
      # Créer un objet User temporaire pour afficher les erreurs dans la vue
      @user = User.new(user_only_params)

      # Gérer les erreurs spécifiques
      error_messages = result.errors
      if error_messages.any? { |msg| msg.include?("already been taken") || msg.include?("already used") }
        @user.errors.add(:email_address, "Cette adresse email est déjà utilisée")
        flash.now[:alert] = "Cette adresse email est déjà utilisée. Veuillez utiliser une autre adresse ou vous connecter."
      else
        @user.errors.add(:base, error_messages.join(", "))
        flash.now[:alert] = error_messages.join(", ")
      end

      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation, :cgu, :privacy_policy, :newsletter_subscribed, :first_name, :last_name)
  end

  def user_only_params
    params.require(:user).permit(:email_address, :password, :password_confirmation, :cgu, :privacy_policy)
  end
end
