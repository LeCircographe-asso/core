class AddUserIdToPayments < ActiveRecord::Migration[8.0]
  def change
    add_reference :payments, :user, null: true, foreign_key: true
  end
end
