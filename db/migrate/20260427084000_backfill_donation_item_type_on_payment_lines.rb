class BackfillDonationItemTypeOnPaymentLines < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE payment_lines
      SET item_type = 'Donation'
      WHERE item_type = 'Payment'
        AND (
          LOWER(COALESCE(description, '')) LIKE '%don%'
          OR COALESCE(description, '') = 'Donation'
        )
    SQL
  end

  def down
    execute <<~SQL
      UPDATE payment_lines
      SET item_type = 'Payment'
      WHERE item_type = 'Donation'
        AND (
          LOWER(COALESCE(description, '')) LIKE '%don%'
          OR COALESCE(description, '') = 'Donation'
        )
    SQL
  end
end
