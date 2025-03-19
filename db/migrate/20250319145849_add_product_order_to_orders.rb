class AddProductOrderToOrders < ActiveRecord::Migration[8.0]
  def change
    add_reference :orders, :product_order, null: false, foreign_key: true
  end
end
