class OrdersController < ApplicationController
  before_action :set_order, only: [:show, :edit, :update, :destroy]

  def index
    @orders = Order.all
  end

  def show
    @product = Product.find(@order.product_id)
    @order = Order.find(params[:id])
    @price_entry = @order.product.price_entries.where(active: true).order(created_at: :desc).first
    @price_catalog = @price_entry.price_catalog if @price_entry
    @total = @order.sum
  end


  def new
    @order = Order.new
    @products = Product.all
  end

  def create
    @order = Order.new(order_params)
    if @order.save
      redirect_to @order, notice: 'Commande créée avec succès'
    else
      render :new
    end
  end


  def edit
    @product = Product.find(@order.product_id)
    @price_catalog = PriceCatalog.find(@product.price_catalog_id)
  end

  def update
    if @order.update(order_params)
      redirect_to @order, notice: 'Commande mise à jour avec succès'
    else
      render :edit
    end
  end

  def destroy
    @order.destroy
    redirect_to orders_url, notice: 'Commande supprimée avec succès'
  end

  private

  def set_order
    @order = Order.find(params[:id])
  end

  def order_params
    params.require(:order).permit(:product_id, :user_id, :sum)
  end
end
