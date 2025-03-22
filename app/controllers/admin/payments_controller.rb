module Admin
  class PaymentsController < BaseController

    def new 
      @payment = Payment.new
    end

    def show
      @payments = Payment.all
      @payment = Payment.find(params[:id])
      @product_order = @payment.product_order

    end 
    
    def create
        @user = User.find(payment_params[:user_id])
        @product_order = ProductOrder.find(payment_params[:product_order_id])
        @payment = Payment.new(payment_params)
        
        puts"#{@product_order.inspect}"
        puts"********************************************************************************************************************************"
        if @payment.save
          puts"#{@payment.id}"
          redirect_to admin_payment_path(@payment), notice: 'Cotisation prise en compte'  
        else 
          redirect_to admin_product_order_path, notice: ' You fuck it up'
        end 
    end 

    def update
      @payment = Payment.find(params[:id])
      @product_order = ProductOrder.find_by(id: payment_params[:product_order_id])

      if @payment.update(status: 'success')
        redirect_to admin_payment_path(@payment), notice: 'Mise à jour réussie'
      else
        redirect_to admin_payment_path(@payment), alert: 'Échec de la mise à jour'
      end
    end 


    private 

    def payment_params
      params.require(:payment).permit(:payment_id ,:payment_date, :payment_amount, :payment_type, :status, :user_id, :product_order_id)
    end
  end 
end 
