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
              render turbo_stream: [
                turbo_stream.replace("product-container", partial: determine_product_partial, locals: { order: @order, user: @user }),
                turbo_stream.replace("total_price", partial: "admin/orders/total_price", locals: { order: @order }), # Mettre à jour le total
                turbo_stream.replace("total-donation", partial: "admin/orders/total_donation", locals: { order: @order, user: @user })
            ]
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

    def destroy
      @order = Order.find(params[:order_id])  # Trouve la commande par son ID
      @product_order = @order.product_orders.find(params[:id])  # Trouve le ProductOrder par son ID

      @product_order.destroy  # Supprime la ligne de la table de jointure

      @products_membership = Product.where(product_type: "adhésion")
      @product_subscription = Product.where(product_type: "cotisation")

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.remove("product_order_#{@product_order.id}"), # Supprimer la ligne du produit
            turbo_stream.replace("total_price", partial: "admin/orders/total_price", locals: { order: @order }), # Mettre à jour le total
            turbo_stream.replace("product-container", partial: "admin/orders/product_container", locals: { order: @order, has_valid_membership: @has_valid_membership }) # Re check le panier et affiche le bon partial en fonction
          ]
        end
        format.html { redirect_to admin_user_order_path(@order) }
      end
    end


    private

    def set_order
      @order = Order.find(product_order_params[:order_id])
    end

    def set_product_order
      @product_order = ProductOrder.find(params[:id])
    end

    def product_order_params
      params.require(:product_order).permit(:product_id, :user_id, :order_id, :product_order_id)
    end

    def determine_product_partial
      @order.products.any? { |product| product.product_type == "adhesion" } ? "admin/orders/product_subscription" : "admin/orders/product_membership"
    end
  end
end
