class CreatePriceCatalogs < ActiveRecord::Migration[8.0]
  def change
    create_table :price_catalogs do |t|
      t.boolean :active
      t.integer :price

      t.timestamps
    end
  end
end
