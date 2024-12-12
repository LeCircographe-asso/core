class UsersController < ApplicationController
  allow_unauthenticated_access only: %i[ new show create newsletter_signup]
  def index
    @users = User.all
  end

  def show
    authenticated?
    @user = User.find(params[:id])
    if !Current.user.has_privileges? && @user.id != Current.user.id
      redirect_to user_path(Current.user.id)
    end

    @public_attributes = {
      "Prénom" => @user.first_name,
      "Nom" => @user.last_name,
      "Adresse Mail" => @user.email_address,
      "Newsletter" => @user.newsletter,
      "Abonnement" => @user.subscription_types.order(:created_at).last.name
    }
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to @user, notice: "Utilisateur créé avec succès."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    if @user.update(user_params)
      redirect_to @user, notice: "Utilisateur mis à jour avec succès."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @user = User.find(params[:id])
    @user.destroy
    redirect_to users_path, notice: "Utilisateur supprimé avec succès."
  end

  def newsletter_signup
    email = params[:email]

    if email.blank?
      flash[:alert] = "Veuillez entrer une adresse email valide."
      redirect_back fallback_location: root_path
      return
    end

    result = NewsletterSignupService.new(email, authenticated? ? Current.user : nil).call_newsletter

    if result[:success]
      flash[:notice] = result[:message]
    else
      flash[:alert] = result[:message]
    end

    redirect_back fallback_location: root_path
  end

  def unsubscribe
    @user = User.find(params[:id])
    @user.update(newsletter: false)
    redirect_to @user, notice: "Vous avez été désinscrit de la newsletter"
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end
