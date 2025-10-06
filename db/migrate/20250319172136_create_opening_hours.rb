class CreateOpeningHours < ActiveRecord::Migration[8.0]
  def change
    create_table :opening_hours do |t|
      t.time :open_at, null: false
      t.time :close_at, null: false
      t.integer :day, null: false

      t.timestamps
    end
  end
end
