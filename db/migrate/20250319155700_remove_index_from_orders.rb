class RemoveIndexFromOrders < ActiveRecord::Migration[6.0]  # Assure-toi que la version correspond à celle que tu utilises
  def change
    remove_index :orders, name: "index_orders_on_product_order_id"
  end
end
