class AddSystemRoleToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :system_role, :integer, default: 3, null: false
  end
end
