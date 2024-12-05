class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.string :title, null: false
      t.text :upper_description
      t.text :middle_description
      t.text :bottom_description
      t.string :location
      t.datetime :date, null: false
      t.references :creator, null: false, foreign_key: { to_table: :users }
      t.string :picture_url

      t.timestamps
    end
  end
end
