class CreateBoardMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :board_members do |t|
      t.string  :name,           null: false
      t.string  :role,           null: false
      t.text    :bio
      t.integer :display_order,  null: false
      t.string  :instagram_url
      t.string  :linkedin_url
      t.string  :behance_url

      t.timestamps
    end

    add_index :board_members, :display_order
  end
end
