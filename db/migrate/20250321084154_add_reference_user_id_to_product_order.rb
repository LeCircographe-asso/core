class AddReferenceUserIdToProductOrder < ActiveRecord::Migration[8.0]
  def change
    add_reference :product_orders, :user, foreign_key: true, null: true
  end
end
