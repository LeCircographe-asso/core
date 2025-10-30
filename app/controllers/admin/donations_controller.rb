module Admin
  class DonationsController < BaseController
    def create
      @user = User.find(params[:user_id])
      @person = @user.person

      begin
        # Créer la donation directement via le modèle Person
        payment = @person.create_donation!(
          amount_cents: payment_params[:payment_amount].to_f * 100,
          payment_method: :cash,
          recorded_by: Current.user,
          notes: "Donation"
        )

        redirect_to admin_payment_path(payment), notice: "Donation prise en compte"
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
