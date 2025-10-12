module Admin
  class ProductsController < BaseController
    before_action :set_product, only: [ :show, :edit, :update, :destroy ]

    def index
      @products = Product.all
    end

    def show
      @product = Product.find(params[:id])
      @price_entry = @product.price_entries.where(active: true).order(created_at: :desc).first
      @price_catalog = @price_entry.price_catalog if @price_entry
    end

    def new
      @product = Product.new
      @price_catalogs = PriceCatalog.all
    end

    def create
      @product = Product.create(product_params)
      if @product.save
        redirect_to admin_product_path(@product), notice: "Produit créé avec succès"
      else
        render :new
      end
    end

    def edit
      @price_entry = PriceEntry.where(product_id: @product.id).first
      @price_catalog = PriceCatalog.find(@price_entry.price_catalog_id) if @price_entry
      @price_catalogs = PriceCatalog.all
    end

    def update
      if @product.update(product_params)
        redirect_to admin_product_path(@product), notice: "Produit mis à jour avec succès"
      else
        render :edit
      end
    end

    def destroy
      @product.destroy
      redirect_to admin_products_path, notice: "Produit supprimé avec succès"
    end

    private

    def set_product
      @product = Product.find(params[:id])
    end

    def product_params
      params.require(:product).permit(:product_name, :product_type)
    end
  end
end
