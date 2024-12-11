module Admin
  class MembersController < BaseController
    include UserParams

    def index
      @users = User.all
    end

    def show
      @user = User.find(params[:id])
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

      redirect_to admin_members_path
    end

    private

    def user_params
      params.require(:user).permit(:email_address, :password, :password_confirmation)
    end
  end
end
