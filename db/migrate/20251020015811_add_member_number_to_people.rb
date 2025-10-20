class AddMemberNumberToPeople < ActiveRecord::Migration[8.0]
  def change
    add_column :people, :member_number, :string
    add_index :people, :member_number, unique: true
  end
end
