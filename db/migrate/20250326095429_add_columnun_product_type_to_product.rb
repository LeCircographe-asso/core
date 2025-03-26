class AddColumnunProductTypeToProduct < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :product_type, :string
  end
end
