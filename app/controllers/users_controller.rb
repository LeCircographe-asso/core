class UsersController < ApplicationController
  include UsersHelper
  before_action :set_user, only: %i[ show edit update destroy ] # THIS WAS SCAFFOLD
  allow_unauthenticated_access only: %i[new show create]

  # GET /users or /users.json
  def index
    @users = User.all
  end

  def show
    @user = User.find(params[:id])
  end

  def new
    @user = User.new
  end

  def edit
    @user = User.find(params[:id])
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
    if @user.nil?
      render plain: "Utilisateur introuvable", status: :not_found
    end
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
    @user.destroy!

    respond_to do |format|
      format.html { redirect_to users_path, status: :see_other, notice: "Utilisateur supprimé avec succès." }
      format.json { head :no_content }
    end
  end

  def change_newsletter_status
    @user = User.find(params[:id])
    @user.update(newsletter: !@user.newsletter)

    message = @user.newsletter ? "Vous êtes inscrit à la newsletter" : "Vous êtes désinscrit de la newsletter"
    redirect_to @user, notice: message
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def user_params
      params.fetch(:user, {})
      params.require(:user).permit(:email_address)
    end
end
