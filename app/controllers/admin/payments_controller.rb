module Admin
  class PaymentsController < BaseController

    def index
      @payments=Payment.all
      @payment= Payment.find_by(params[:id])
      @user = User.find_by(id: params[:user_id])
      

    end 

    def new 
      @payment = Payment.new
    end

    def show
      @payments = Payment.all
      @payment = Payment.find(params[:id])
      @order = Order.find_by(id: @payment.order_id)
      

    end 
    
    def create
      puts "#"*111
      puts"#{@product_order.inspect}"
        @user = User.find(payment_params[:user_id])

        @payment = Payment.new(payment_params)
        
        

        if @payment.save
          puts"#{@payment.id}"
          puts"#{@payment.inspect}"
          redirect_to admin_payment_path(@payment), notice: 'Cotisation prise en compte'  
        else 
          redirect_to admin_product_order_path, notice: ' You fuck it up'
        end 
    end 

    def update
      @payment = Payment.find(params[:id])
      p "#"*111
      p @payment
      p "#"*111
        puts "Order ID: #{@payment.order.id}"
        puts "Product orders: #{@payment.order.product_orders.inspect}"
      p "#"*111
      if @payment.update(payment_params)
        puts"#{@payment.inspect}"
        redirect_to admin_payment_path(@payment), notice: 'Mise à jour réussie'
      else
        puts"#{@payment.inspect}"
        redirect_to admin_payment_path(@payment), alert: 'Échec de la mise à jour'
      end
    end 


    private 

    def payment_params
      params.require(:payment).permit(:payment_id ,:payment_date, :payment_amount, :payment_type, :status, :user_id, :order_id)
    end
  end 
end 
