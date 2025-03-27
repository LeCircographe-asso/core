class CreatePayment < ActiveRecord::Migration[8.0]
  def change
    create_table :payments do |t|
      t.datetime :payment_date
      t.decimal :payment_amount
      t.integer :payment_type
      t.integer :status
      t.timestamps
    end
  end
end
