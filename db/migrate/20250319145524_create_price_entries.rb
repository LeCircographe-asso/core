class CreatePriceEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :price_entries do |t|
      t.references :product, null: false, foreign_key: true
      t.references :price_catalog, null: false, foreign_key: true

      t.timestamps
    end
  end
end
