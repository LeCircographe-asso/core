class AddDonationToPayments < ActiveRecord::Migration[8.0]
  def change
    add_column :payments, :donation, :decimal
  end
end
