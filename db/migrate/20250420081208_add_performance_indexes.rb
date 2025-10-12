class AddPerformanceIndexes < ActiveRecord::Migration[8.0]
  def change
    # Add indexes to frequently queried columns
    add_index :payments, :status, if_not_exists: true
    add_index :payments, :payment_date, if_not_exists: true
    add_index :payments, :payment_amount, if_not_exists: true
    add_index :payments, :user_id, if_not_exists: true
    add_index :payments, :order_id, if_not_exists: true

    add_index :orders, :user_id, if_not_exists: true
    add_index :orders, :donation, if_not_exists: true

    add_index :product_orders, :product_id, if_not_exists: true
    add_index :product_orders, :order_id, if_not_exists: true

    add_index :users, :email_address, if_not_exists: true
    add_index :users, :deleted, if_not_exists: true

    add_index :user_memberships, [ :user_id, :status ], if_not_exists: true
  end
end
