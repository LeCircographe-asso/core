class AddTotalPaymentToPayments < ActiveRecord::Migration[8.0]
  def change
    add_column :payments, :total_payment, :decimal
  end
end
