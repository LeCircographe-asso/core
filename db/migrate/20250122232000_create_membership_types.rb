class CreateMembershipTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :membership_types do |t|
      t.string :name, null: false
      t.decimal :price, null: false
      t.integer :duration, null: false
      t.string :category, null: false
      t.text :description
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :membership_types, :name, unique: true
    add_index :membership_types, [:category, :active]
  end
end 