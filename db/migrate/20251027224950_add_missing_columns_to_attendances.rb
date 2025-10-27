class AddMissingColumnsToAttendances < ActiveRecord::Migration[8.1]
  def change
    add_column :attendances, :attendance_list_id, :integer
    add_column :attendances, :book_of_entry_id, :integer
    add_column :attendances, :user_id, :integer
  end
end
