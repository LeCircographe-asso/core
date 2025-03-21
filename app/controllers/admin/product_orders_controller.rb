module Admin
  class ProductOrdersController < BaseController
    before_action :set_order, only: %i[create]

    def show
    end

    def create
      @user = User.find(product_order_params[:user_id])
      product = Product.find(product_order_params[:product_id])
      @order = Order.find(product_order_params[:order_id])
      @product_order = ProductOrder.new(product: product, order: @order, user_id: @user.id)

      @products_membership = Product.where(product_type: "adhésion")
      @product_subscription = Product.where(product_type: "cotisation")
        if @product_order.save
          respond_to do |format|
            format.html { redirect_to admin_user_orders_path(@user), notice: "Produit ajouté à la commande avec succès." }
            format.turbo_stream {
              render turbo_stream:
                turbo_stream.replace("product-container", partial: determine_product_partial, locals: { order: @order, user: @user })
            }
          end
        else
          respond_to do |format|
            format.html { redirect_to admin_user_orders_path(@user), alert: "Impossible d'ajouter ce produit à la commande." }
            format.turbo_stream { render turbo_stream: turbo_stream.replace("product-container", html: "Erreur lors de l'ajout du produit.") }
          end
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

    def determine_product_partial
      @order.products.any? { |product| product.product_type == "adhesion" } ? "admin/orders/product_subscription" : "admin/orders/product_membership"
    end
  end
end
