class AddReferenceToAttendances < ActiveRecord::Migration[8.0]
  def change
    add_reference :attendances, :attendance_list, foreign_key: true, null: false
    add_reference :attendances, :user, foreign_key: true, null: false
    add_reference :attendances, :book_of_entry, foreign_key: true, null: true
  end
end
