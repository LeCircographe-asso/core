class AddNameToAttendanceLists < ActiveRecord::Migration[8.0]
  def up
    add_column :attendance_lists, :name, :string

    # Add default values for existing records
    AttendanceList.reset_column_information
    AttendanceList.all.each_with_index do |list, index|
      name = case list.list_type
      when 'training'
               "Registre de présence #{list.start_date.strftime("%d/%m/%Y")}"
      when 'event'
               "Événement du #{list.start_date.strftime("%d/%m/%Y")}"
      when 'meeting'
               "Réunion du #{list.start_date.strftime("%d/%m/%Y")}"
      else
               "Liste de présence ##{list.id}"
      end
      list.update_column(:name, name)
    end
  end

  def down
    remove_column :attendance_lists, :name
  end
end
