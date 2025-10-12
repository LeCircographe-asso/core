class SettingsController < ApplicationController
  before_action :require_authentication
  def show
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update(user_params)
      flash[:notice] = "Vos modifications ont été enregistrées avec succès"
      redirect_to user_path(@user), status: :see_other
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(
      :email_address, :image_rights,
      :newsletter_subscribed, :get_involved,
      :dyslexic_font
    )
  end
end
