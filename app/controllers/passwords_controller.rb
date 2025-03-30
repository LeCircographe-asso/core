class PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[edit update]

  def new
    @user = User.find_by(email_address: params[:email_address])
  end

  def create
    Rails.logger.debug "----- CREATE ACTION STARTED -----"
    Rails.logger.debug "PARAMS RECEIVED: #{params.inspect}"
  
    # Recherche l'utilisateur par adresse email
    user = User.find_by(email_address: params[:email_address])
    if user
      Rails.logger.debug "USER FOUND: #{user.inspect}"
  
      # Génération d'un token de réinitialisation pour l'utilisateur
      user.generate_password_reset_token!
      Rails.logger.debug "PASSWORD RESET TOKEN GENERATED: #{user.password_reset_token}"
  
      # Si l'utilisateur a été créé par un administrateur
      if user.created_by_admin?
        Rails.logger.debug "SENDING welcome_by_admin EMAIL to USER: #{user.email_address}"
        PasswordsMailer.welcome_by_admin(user).deliver_now
      else
        Rails.logger.debug "SENDING reset_password EMAIL to USER: #{user.email_address}"
        PasswordsMailer.reset_password(user).deliver_now
      end
  
      # Redirection en cas de succès
      Rails.logger.debug "REDIRECTING to new_session_path"
      redirect_to new_session_path, notice: "Instructions de réinitialisation envoyées si l'email existe."
      return
    end
  
    # Si aucun utilisateur n'est trouvé
    Rails.logger.debug "NO USER FOUND WITH EMAIL: #{params[:email_address]}"
    redirect_to new_session_path, alert: "Aucun utilisateur trouvé avec cette adresse email, mais nous ne pouvons pas confirmer cela pour des raisons de sécurité."
  ensure
    Rails.logger.debug "----- CREATE ACTION COMPLETED -----"
  end
  


  def edit
    @user = User.find_by(password_reset_token: params[:token])
    render :edit
  end

  def update
    if @user.update(params.permit(:password, :password_confirmation))
      @user.clear_password_reset_token!
      redirect_to new_session_path, notice: "Mot de passe réinitialisé avec succès."
    else
      flash.now[:alert] = "Les mots de passe ne correspondent pas."
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def password_params
    params.permit(:email_address) # Autorise le paramètre attendu
  end

  def set_user_by_token
    @user = User.find_by(password_reset_token: params[:token])
    unless @user&.password_reset_token_valid?
      redirect_to new_password_path, alert: "Le lien de réinitialisation est invalide ou expiré."
    end
  end
end
