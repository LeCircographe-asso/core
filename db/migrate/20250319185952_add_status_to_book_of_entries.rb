class AddStatusToBookOfEntries < ActiveRecord::Migration[7.0]
  def change
    add_column :book_of_entries, :status, :integer
  end
end
