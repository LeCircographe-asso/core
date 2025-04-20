class AddDeletedAtToRelatedModels < ActiveRecord::Migration[8.0]
  def change
    # Add deleted_at column to orders table
    add_column :orders, :deleted_at, :datetime
    add_index :orders, :deleted_at

    # Add deleted_at column to payments table
    add_column :payments, :deleted_at, :datetime
    add_index :payments, :deleted_at

    # Add deleted_at column to user_memberships table
    add_column :user_memberships, :deleted_at, :datetime
    add_index :user_memberships, :deleted_at

    # Add deleted_at column to book_of_entries table
    add_column :book_of_entries, :deleted_at, :datetime
    add_index :book_of_entries, :deleted_at

    # Add deleted_at column to attendances table
    add_column :attendances, :deleted_at, :datetime
    add_index :attendances, :deleted_at
  end
end 