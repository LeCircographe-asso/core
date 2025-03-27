class CreateBookOfEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :book_of_entries do |t|
      t.references :product, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :remaining
      t.integer :total_entry

      t.timestamps
    end
  end
end
