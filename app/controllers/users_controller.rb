class UsersController < ApplicationController
  include UsersHelper
  before_action :set_user, only: %i[ show edit update destroy ] # THIS WAS SCAFFOLD
  skip_before_action :require_authentication, only: %i[create]

  def show
    @user = Current.user
  end

  def edit
    @user = Current.user
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

  def update
    @user = Current.user
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
    @user.update(newsletter: !@user.newsletter)

    message = @user.newsletter ? "Vous êtes inscrit à la newsletter" : "Vous êtes désinscrit de la newsletter"
    redirect_to @user, notice: message
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = Current.user
    end

    # Only allow a list of trusted parameters through.
    def user_params
      params.fetch(:user, {})
      params.require(:user).permit(:email_address)
    end
end
