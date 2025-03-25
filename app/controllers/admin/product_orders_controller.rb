module Admin
  class ProductOrdersController < BaseController
    before_action :set_order , only: %i[create]

    def show 
      @product_order = ProductOrder.find(params[:id])
      @user = @product_order.user_id
      @order = @product_order.order_id
      @product = Product.all
    end 

    def create
      
      @user = User.find(product_order_params[:user_id])
      product = Product.find(product_order_params[:product_id])
      @order = Order.find(product_order_params[:order_id])
      @products = Product.all
      @product_order = ProductOrder.new(product: product, order: @order, user_id: @user.id)

      if @product_order.save
        puts @product_order.inspect
        puts "********************************************************************************************************************************"
        redirect_to admin_product_order_path(@product_order), notice: 'Produit ajouté à la commande avec succès.'
        
      else
        render 'admin/products/index' ,alert: 'Impossible d\'ajouter ce produit à la commande.'
        puts @product_order.errors.full_messages
      end
    end
    def update
      @product_order = ProductOrder.find(params[:id])
      @product = Product.find(params[:product_order][:product_id])
      @user = User.find(params[:product_order][:user_id])
  
      @product_order.product << @product
    end

    private

    def set_order
      @order = Order.find(product_order_params[:order_id]) 
    end

    def product_order_params
      params.require(:product_order).permit(:product_id, :user_id, :order_id)
    end

  end
end

