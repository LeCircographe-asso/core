class CreateProductOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :product_orders do |t|
      t.references :product, null: false, foreign_key: true
      t.references :order, null: false, foreign_key: true

      t.timestamps
    end
  end
end
