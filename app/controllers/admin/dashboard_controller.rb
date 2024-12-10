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
    @membership_data = session[:membership_data] || {}
  end

  def membership_recap
    session[:membership_data] = params[:membership_data] if params[:membership_data].present?
    @membership_data = session[:membership_data] || {}
  end

  def membership_payment
    @membership_data = params[:membership_data] || {}
    @payment_methods = ['Carte bancaire', 'Chèque', 'Espèces']
  end

  def membership_complete
    if params[:action_type] == 'validate'
      flash[:notice] = "Adhésion validée avec succès !"
    elsif params[:action_type] == 'pending'
      flash[:alert] = "Adhésion mise en attente."
    elsif params[:action_type] == 'cancel'
      flash[:alert] = "Adhésion annulée."
    end
  
    redirect_to admin_dashboard_path
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
