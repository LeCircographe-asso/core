class RenameOrderIdToProductOrderIdInPayments < ActiveRecord::Migration[8.0]
  def change
    rename_column :payments, :order_id, :product_order_id
    remove_foreign_key :payments, :orders
    add_foreign_key :payments, :product_orders
  end
end
