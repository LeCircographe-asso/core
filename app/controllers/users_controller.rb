class UsersController < ApplicationController
  include UsersHelper
  allow_unauthenticated_access only: %i[new show create]

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
      "Prénom"       => @user.first_name,
      "Nom"          => @user.last_name,
      "Adresse Mail" => @user.email_address,
      "Newsletter" => @user.newsletter,
      "Abonnement" => @user.subscription_types.order(:created_at).last&.name || "Aucun abonnement"
    }
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    return newsletter_signup(user_params[:email_address]) unless user_params[:password]
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
