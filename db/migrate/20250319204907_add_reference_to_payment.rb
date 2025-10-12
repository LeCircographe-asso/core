class AddReferenceToPayment < ActiveRecord::Migration[8.0]
  def change
    add_reference :payments, :user, foreign_key: true, null: false
    add_reference :payments, :order, foreign_key: true, null: false
  end
end
