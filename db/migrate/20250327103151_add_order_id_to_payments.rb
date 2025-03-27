class AddOrderIdToPayments < ActiveRecord::Migration[8.0]
  def change
    remove_column :orders, :product_order_id, :integer
    remove_column :payments, :product_order_id, :integer
    add_column :payments, :order_id, :integer
  end
end
