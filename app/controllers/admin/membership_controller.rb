module Admin
class MembershipController < BaseController
  before_action :set_products, only: [ :index ]


  def index
    @user = User.find(params[:user_id])
    @orders = @user.orders.includes(:product_orders)
    @products = Product.all
  end


  def create
      @user = User.find(params[:user_id])
      @product = Product.find(params[:product_id])
      # Ajoutez le produit à la commande
      @order.product_orders.create(product: @product)

      redirect_to admin_membership_index_path(user_id: @user.id), notice: "Produit ajouté à la cotisation."
  end


  private

  def set_products
    @products = Product.all
  end
end
end
