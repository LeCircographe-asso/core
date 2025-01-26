class CreateAttendanceStatistics < ActiveRecord::Migration[8.0]
  def change
    create_table :attendance_statistics do |t|
      t.string :period_type, null: false  # daily, weekly, monthly, yearly
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.integer :total_visits, default: 0
      t.integer :unique_visitors, default: 0
      t.integer :visitor_count, default: 0
      t.integer :peak_attendance
      t.datetime :peak_time
      t.text :notes

      t.timestamps

      t.index :period_type
      t.index :start_date
      t.index [:period_type, :start_date], unique: true
    end
  end
end 