class AddSuspendedStatusToBookOfEntries < ActiveRecord::Migration[8.0]
  def change
    # Add suspended status to enum (value 4)
    add_column :book_of_entries, :suspended_at, :datetime
    add_column :book_of_entries, :suspended_reason, :text

    # Update existing enum values to make room for suspended status
    # Suspended will be value 4 in the enum
    reversible do |dir|
      dir.up do
        # No need to update existing data, just add new enum value
      end
      dir.down do
        # Remove suspended book_of_entries when rolling back
        execute <<-SQL
          UPDATE book_of_entries SET status = 0 WHERE status = 4;
        SQL
      end
    end
  end
end
