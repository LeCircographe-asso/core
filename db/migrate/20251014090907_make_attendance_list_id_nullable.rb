class MakeAttendanceListIdNullable < ActiveRecord::Migration[8.0]
  def change
    # Rendre attendance_list_id nullable pour permettre les présences sans liste
    change_column_null :attendances, :attendance_list_id, true
  end
end
