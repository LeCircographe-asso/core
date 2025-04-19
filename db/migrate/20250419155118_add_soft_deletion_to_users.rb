class AddSoftDeletionToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :deleted, :boolean, default: false, null: false
    add_column :users, :deleted_at, :datetime

    # Add index for better performance when querying deleted status
    add_index :users, :deleted
  end
end
