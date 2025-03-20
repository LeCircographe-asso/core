class CreateAttendances < ActiveRecord::Migration[8.0]
  def change
    create_table :attendances do |t|
      t.datetime :arrival_time
      t.timestamps
    end
  end
end
