class CreatePartners < ActiveRecord::Migration[8.1]
  def change
    create_table :partners do |t|
      t.string  :name,          null: false
      t.string  :category
      t.text    :bio
      t.string  :url
      t.string  :initials
      t.integer :display_order, null: false

      t.timestamps
    end

    add_index :partners, :display_order
  end
end
