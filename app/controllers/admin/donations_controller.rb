module Admin
  class DonationsController < BaseController
    def create
      @user = User.find(params[:user_id])
      @person = @user.person

      begin
        # Utiliser le service PaymentManagement::PaymentCreator pour cohérence
        creator = PaymentManagement::PaymentCreator.new(
          person_id: @person.id,
          amount_cents: (payment_params[:payment_amount].to_f * 100).to_i,
          payment_method: "cash",
          recorded_by_id: Current.user.id,
          item_type: "Donation",
          item_id: @person.id, # Pour donations, item_id = person_id
          description: "Donation",
          notes: "Donation"
        )

        result = creator.call

        if result.success?
          redirect_to admin_payment_path(result.payment), notice: "Donation prise en compte"
        else
          flash[:alert] = "Erreur lors de la création de la donation: #{result.message}"
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
