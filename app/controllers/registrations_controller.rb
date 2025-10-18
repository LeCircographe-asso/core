class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  def new
    if authenticated?
      redirect_to root_path
    end
    @user = User.new(email_address: session[:newsletter_email])
  end

  def create
    # Trouver l'adhésion Basic par défaut
    basic_membership = MembershipType.find_by(category: :basic)
    
    if basic_membership.nil?
      flash.now[:alert] = "Erreur système: adhésion de base non trouvée"
      render :new, status: :unprocessable_entity
      return
    end

    # Utiliser People::Register pour créer Person + User + Membership
    result = People::Register.new(
      first_name: user_params[:first_name] || "Utilisateur",
      last_name: user_params[:last_name] || "Anonyme", 
      email: user_params[:email_address],
      membership_type_id: basic_membership.id,
      payment_method: "pending", # À payer plus tard
      create_user_account: true,
      user_email: user_params[:email_address],
      user_password: user_params[:password],
      user_system_role: "user_connected"
    ).call
    
    if result.success?
      UserMailer.welcome_email(result.user).deliver_later
      start_new_session_for result.user
      redirect_to root_path, notice: "Inscription réussie !"
    else
      flash.now[:alert] = result.errors.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation, :cgu, :privacy_policy, :newsletter_subscribed, :first_name, :last_name)
  end
end
