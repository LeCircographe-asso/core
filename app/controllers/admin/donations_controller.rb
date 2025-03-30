module Admin
  class DonationsController < BaseController

    def create
      @user = User.find(params[:user_id])  
      @order = Order.create!(user: @user) 
      @payment = Payment.new(payment_params.merge(order_id: @order.id)) 

      begin
        Payment.transaction do
          if @payment.save
            redirect_to admin_payment_path(@payment), notice: 'Donation prise en compte'
          else
            flash[:alert] = "Échec de la création du paiement"
            render :new
          end
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
