class AddAnonymizationToPayments < ActiveRecord::Migration[8.0]
  def change
    add_column :payments, :anonymized_at, :datetime
    add_column :payments, :original_person_identifier, :string
    add_index :payments, :anonymized_at
  end
end
