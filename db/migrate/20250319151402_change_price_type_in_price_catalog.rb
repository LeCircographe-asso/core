class ChangePriceTypeInPriceCatalog < ActiveRecord::Migration[6.0]
  def change
    change_column :price_catalogs, :price, :decimal
  end
end
