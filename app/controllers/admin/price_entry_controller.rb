module Admin
  class PriceEntryController < BaseController
    before_action :set_product, only: [:new, :create, :index]

    def index
      @price_entries = @product.price_entries.includes(:price_catalog).order(created_at: :desc)
    end

    def new
      @price_entry = PriceEntry.new
      @price_catalogs = PriceCatalog.all
    end

    def create
      @price_entry = @product.price_entries.new(price_entry_params)
      if @price_entry.save
        redirect_to admin_product_price_entries_path(@product), notice: 'Prix associé avec succès.'
      else
        @price_catalogs = PriceCatalog.all
        render :new
      end
    end

    private

    def set_product
      @product = Product.find(params[:product_id])
    end

    def price_entry_params
      params.require(:price_entry).permit(:price_catalog_id)
    end
  end
end 