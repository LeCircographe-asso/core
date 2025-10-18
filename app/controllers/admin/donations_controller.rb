module Admin
  class DonationsController < BaseController
    def create
      @user = User.find(params[:user_id])
      @person = @user.person
      
      # Créer un paiement directement (plus besoin d'Order)
      @payment = Payment.new(
        person: @person,
        recorded_by: Current.user,
        total_cents: payment_params[:payment_amount].to_f * 100,
        payment_method: :cash,
        status: :success,
        notes: "Donation"
      )

      begin
        if @payment.save
          redirect_to admin_payment_path(@payment), notice: "Donation prise en compte"
        else
          flash[:alert] = "Échec de la création du paiement"
          render :new
        end
      rescue => e
        flash[:alert] = "Erreur lors de la création de la donation: #{e.message}"
        render :new
      end
    end

    private

    def payment_params
      params.require(:payment).permit(:payment_amount, :payment_date, :payment_type, :status, :donation, :total_payment, :user_id)
    end
  end
end
