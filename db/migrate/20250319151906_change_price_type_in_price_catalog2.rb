class ChangePriceTypeInPriceCatalog2 < ActiveRecord::Migration[6.0]
  def change
    change_column :price_catalogs, :price, :decimal, precision: 10, scale: 2
  end
end
