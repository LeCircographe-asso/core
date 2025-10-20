class CreateOpeningHours < ActiveRecord::Migration[8.0]
  def change
    # Opening Hours
    create_table "opening_hours", force: :cascade do |t|
      t.time "open_at", null: false
      t.time "close_at", null: false
      t.integer "day", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
  end
end
