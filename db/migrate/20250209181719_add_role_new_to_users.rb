class AddRoleNewToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :role_new, :integer, default: 0, null: false
    add_index :users, :role_new
  end
end
