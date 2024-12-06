class UsersController < ApplicationController
  allow_unauthenticated_access only: %i[ new show create ]
  def index
    @users = User.all
  end

  def show
    @user = User.find(params[:id])
    @public_attributes = {
      "Prénom" => @user.first_name,
      "Nom" => @user.last_name,
      "Adresse Mail" => @user.email_address,
      "Ville" => @user.town
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

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end
