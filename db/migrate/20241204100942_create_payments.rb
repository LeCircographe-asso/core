class CreatePayments < ActiveRecord::Migration[8.0]
  def change
    create_table :payments do |t|
      t.references :user, null: false, foreign_key: true
      t.string :payment_method, null: false
      t.decimal :amount, precision: 8, scale: 2, null: false
      t.decimal :donation_amount, precision: 8, scale: 2, default: 0
      t.string :status, default: 'pending', null: false
      t.references :processed_by, foreign_key: { to_table: :users }
      t.datetime :processed_at

      t.timestamps

      t.index :payment_method
      t.index :status
      t.index :processed_at
    end
  end
end
