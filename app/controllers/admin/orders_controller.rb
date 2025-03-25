module Admin
class OrdersController < BaseController
  before_action :set_order, only: [:show, :edit, :update, :destroy]

  def index
    @orders = Order.all
  end

  def show
    @order = Order.find(params[:id])
    @products = Product.all
    @user = @order.user
  end

  def new
    @order = Order.new

    if @user.membership_status == 'No_Member'
      @products = @products.where(product_name: ['Adhésion simple', 'Adhésion Cirque - Tarif Plein', 'Adhésion Cirque - Tarif Réduit'])
    elsif @user.membership_status == 'Circus'
      @products = @products.where(product_name: ['Upgrade Basic to Cirque - Tarif Plein', 'Upgrade Basic to Cirque - Tarif Réduit'])
    elsif @user.membership_status == 'Basic'
      @products = @products.where(product_name: ['Cotisation 10 séances', 'Cotisation trimestrielle', 'Cotisation annuelle', 'Pass journée'])
    end
  end

  def create
    @user = User.find(params[:user_id]) 
    @order = Order.new(user: @user)
    puts "#{@user.id}"
    Rails.logger.debug "Params reçus: #{params.inspect}"
    puts params.inspect
    if @order.save
      redirect_to admin_order_path(@order) , notice: 'Choisissez Votre Cotisation'
    else
      puts"****************************************************************************************************************************"
    end
  end

  def edit
  end

  def update
    if @order.update(order_params)
      redirect_to admin_order_path(@order), notice: 'Commande mise à jour avec succès.'
    else
      render :edit
    end
  end

  def destroy
    @order.destroy
    redirect_to admin_orders_path, notice: 'Commande supprimée.'
  end

  private

  def set_order
    @order = Order.find(params[:id])
  end

  def order_params
    params.require(:order).permit(:status, :order_id , :user_id)
  end
end
end 