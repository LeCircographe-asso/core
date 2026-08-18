class AddSnapshotFieldsToDonationReceipts < ActiveRecord::Migration[8.1]
  def change
    add_column :donation_receipts, :issuer_address, :text
    add_column :donation_receipts, :donor_name, :string
    add_column :donation_receipts, :donor_address, :text
  end
end
