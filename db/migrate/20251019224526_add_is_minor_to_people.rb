class AddIsMinorToPeople < ActiveRecord::Migration[8.0]
  def change
    add_column :people, :is_minor, :boolean, default: false, null: false
  end
end
