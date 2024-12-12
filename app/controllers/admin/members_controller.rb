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

    def reset_membership
      session.delete(:membership_data)
      redirect_to membership_register_admin_members_path
    end

    def membership_recap
      session[:membership_data] = params.permit(:cirque, :tarif, :graff, :soutien, :prenom, :nom, :date_naissance, :adresse, :code_postal, :ville, :pays, :telephone, :email, :profession, :specialite, :droit_image, :newsletter, :investir, :soutenir_financierement).to_h
      @membership_data = session[:membership_data] || {}
    end

    def membership_payment
      @membership_data = params[:membership_data] || {}
      @payment_methods = [ "Carte bancaire", "Chèque", "Espèces" ]
    end

    def membership_complete
      if params[:action_type] == "validate"
        flash[:notice] = "Adhésion validée avec succès !"
      elsif params[:action_type] == "pending"
        flash[:alert] = "Adhésion mise en attente."
      elsif params[:action_type] == "cancel"
        flash[:alert] = "Adhésion annulée."
      end

      session.delete(:membership_data)
      redirect_to admin_members_path
    end

    private

    def user_params
      params.require(:user).permit(:email_address, :password, :password_confirmation)
    end
  end
end
