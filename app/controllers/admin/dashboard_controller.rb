class Admin::DashboardController < ApplicationController
  # ApplicationController
  before_action :authorize_admin_or_godmode

  def index
    @users = User.all
  end

  def members_list
    @users = User.all
  end

  def member_show
    @user = User.find(params[:user_id])
  end

  def membership_register
    
  end

  private

  def authorize_admin_or_godmode
    unless Current.user&.role.in?(['volunteer','admin', 'godmode'])
      redirect_to root_path, alert: 'Accès non autorisé'
    end
  end

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end

end
