class PriceCatalogController < ApplicationController
  before_action :require_admin_or_super_admin
  before_action :set_price_catalog, only: [:show, :edit, :update, :destroy]

  def index
    @price_catalogs = PriceCatalog.all.order(created_at: :desc)
  end

  def show
  end

  def new
    @price_catalog = PriceCatalog.new
  end

  def create
    @price_catalog = PriceCatalog.new(price_catalog_params)
    if @price_catalog.save
      redirect_to admin_price_catalogs_path, notice: 'Tarif créé avec succès.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @price_catalog.update(price_catalog_params)
      redirect_to admin_price_catalogs_path, notice: 'Tarif mis à jour avec succès.'
    else
      render :edit
    end
  end

  def destroy
    @price_catalog.destroy
    redirect_to admin_price_catalogs_path, notice: 'Tarif supprimé avec succès.'
  end

  private

  def set_price_catalog
    @price_catalog = PriceCatalog.find(params[:id])
  end

  def price_catalog_params
    params.require(:price_catalog).permit(:active, :price)
  end

  def require_admin_or_super_admin
    unless Current.user&.system_role.in?(%w[admin super_admin])
      redirect_to root_path, alert: "Vous n'avez pas accès à cette page."
    end
  end
end
