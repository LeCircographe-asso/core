class CreateDonationReceipts < ActiveRecord::Migration[8.1]
  def change
    create_table :donation_receipts do |t|
      t.references :payment_line, null: false, foreign_key: true, index: { unique: true }
      t.string :number, null: false
      t.datetime :issued_at, null: false
      t.string :issuer, null: false

      t.timestamps
    end

    add_index :donation_receipts, :number, unique: true
  end
end
