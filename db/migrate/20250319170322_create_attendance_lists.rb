class CreateAttendanceLists < ActiveRecord::Migration[8.0]
  def change
    create_table :attendance_lists do |t|
      t.datetime :start_date
      t.datetime :end_date
      t.integer :list_type
      t.integer :status
      t.timestamps
    end
  end
end
