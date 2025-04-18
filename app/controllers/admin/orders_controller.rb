module Admin
class OrdersController < BaseController
  before_action :set_order, only: %i[show edit update destroy]
  before_action :set_breadcrumbs

  def index
    @orders = Order.all
    add_breadcrumb "Commandes", nil
  end

  def show
    @order = Order.find(params[:id])
    @products_membership = Product.where(product_type: "adhesion")
    @product_subscription= Product.where(product_type: "cotisation")
    @user = @order.user
    @product = Product.find_by(params[:id])
    @product_orders = @order.product_orders

    # Add breadcrumbs for user order path
    add_breadcrumb "Liste d'adhérents", admin_users_path
    add_breadcrumb @user.full_name.present? ? @user.full_name : "Utilisateur ##{@user.id}", admin_user_path(@user)
    add_breadcrumb "Commande ##{@order.id}", nil

    respond_to do |format|
      format.html
      format.turbo_stream
    end

    @has_valid_membership = @user.user_memberships.joins(:membership)
      .where(user_memberships: { status: "active" })
      .where(memberships: { type_name: [ "Circus", "Basic" ] })
      .exists?
  end

  def new
    @order = Order.new
    add_breadcrumb "Nouvelle commande", nil
  end

  def create
    @user = User.find(params[:user_id])
    @order = @user.orders.create(order_params)

    if @order.save
        redirect_to admin_user_order_path(@user, @order), notice: "Choisissez Votre Abonnement"
    else
      flash[:error] = "Erreur lors de la création de la commande."
      redirect_to admin_user_path(@user)
    end
  end

  def edit
    add_breadcrumb "Liste d'adhérents", admin_users_path
    add_breadcrumb @order.user.full_name.present? ? @order.user.full_name : "Utilisateur ##{@order.user.id}", admin_user_path(@order.user)
    add_breadcrumb "Commande ##{@order.id}", admin_user_order_path(@order.user, @order)
    add_breadcrumb "Modifier", nil
  end

  def update
    @product = Product.find_by(params[:id])
    @product_orders = @order.product_orders
    @products_membership = Product.where(product_type: "adhesion")
    @product_subscription= Product.where(product_type: "cotisation")
    @order = Order.find(params[:id])

    @total_amount = @order.product_orders.sum { |product_order| product_order.product.price_entries.order(created_at: :desc).first.price_catalog.price }
    @total_donation = @order.donation

    # Assurer que @order.sum a une valeur par défaut (0) si elle est nil
    @order.sum ||= 0

    # Assigner la donation et ajouter à la somme
    @order.donation = params[:order][:donation]
    if @order.donation.present?
      @order.sum += @order.donation.to_f
    end

    if @order.update(order_params)
      respond_to do |format|
        format.html { redirect_to admin_order_path(@order), notice: "Commande mise à jour avec succès." }
        format.turbo_stream {
          render turbo_stream: [
            turbo_stream.replace(
              "product-container",
              partial: "admin/orders/product_container",
              locals: { order: @order, user: @user }
            ),
            turbo_stream.replace(
              "total-donation",
              partial: "admin/orders/total_donation",
              locals: { order: @order, user: @user }
            )
          ]
        }
      end
    else
      respond_to do |format|
        format.html { render :edit }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("product-container", html: "Erreur lors de la mise à jour de la commande") }
      end
    end
  end


  def destroy
    @order.destroy
    redirect_to admin_orders_path, notice: "Commande supprimée."
  end

  private

  def set_order
    @order = Order.find(params[:id])
  end

  def order_params
    params.require(:order).permit(:user_id, :sum, :date, :donation)
  end

  def set_breadcrumbs
    # No need to add dashboard breadcrumb as it's already in the partial
  end
end
end
