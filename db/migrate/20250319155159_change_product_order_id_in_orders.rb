class ChangeProductOrderIdInOrders < ActiveRecord::Migration[8.0]
  def change
    change_column_null :orders, :product_order_id, true
  end
end
