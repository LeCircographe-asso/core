class CreateMembershipsTable < ActiveRecord::Migration[8.0]
  def change
    create_table :memberships do |t|
      t.integer :type_name
      t.timestamps
    end
  end
end
