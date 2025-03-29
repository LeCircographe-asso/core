class AddColumnDonationToOrder < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :donation, :decimal
  end
end
