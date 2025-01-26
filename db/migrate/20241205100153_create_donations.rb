class CreateDonations < ActiveRecord::Migration[8.0]
  def change
    create_table :donations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :payment, null: false, foreign_key: true
      t.decimal :amount, precision: 8, scale: 2, null: false
      t.text :notes
      t.string :status, default: 'pending', null: false
      t.references :processed_by, foreign_key: { to_table: :users }
      t.datetime :processed_at

      t.timestamps

      t.index :status
      t.index :processed_at
    end
  end
end
