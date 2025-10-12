class AddUuidToPayments < ActiveRecord::Migration[8.0]
  def change
    add_column :payments, :uuid, :string
    add_index :payments, :uuid, unique: true
  end
end
