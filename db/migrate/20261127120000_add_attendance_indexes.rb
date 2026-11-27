# frozen_string_literal: true

# Front-desk hot paths: daily training list lookup (check-in, daily presenter)
# filters on list_type + start_date; list index sorts on start_date; the two
# attendances foreign keys were never indexed.
class AddAttendanceIndexes < ActiveRecord::Migration[8.1]
  def change
    add_index :attendance_lists, %i[list_type start_date]
    add_index :attendance_lists, :start_date
    add_index :attendances, :attendance_list_id
    add_index :attendances, :contribution_id
  end
end
