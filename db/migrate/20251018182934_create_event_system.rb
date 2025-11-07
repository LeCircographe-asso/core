class CreateEventSystem < ActiveRecord::Migration[8.0]
  def change
    # Event System
    create_table "events", force: :cascade do |t|
      t.string "name", null: false
      t.text "upper_description"
      t.text "middle_description"
      t.text "bottom_description"
      t.string "location"
      t.datetime "date", null: false
      t.bigint "creator_id", null: false
      t.string "picture_url"
      t.integer "category", default: 0
      t.text "description"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index [ "category" ], name: "index_events_on_category"
      t.index [ "creator_id" ], name: "index_events_on_creator_id"
      t.index [ "date" ], name: "index_events_on_date"
    end

    create_table "event_attendees", force: :cascade do |t|
      t.bigint "user_id", null: false
      t.bigint "event_id", null: false
      t.bigint "payment_id"
      t.boolean "interested", default: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index [ "event_id" ], name: "index_event_attendees_on_event_id"
      t.index [ "payment_id" ], name: "index_event_attendees_on_payment_id"
      t.index [ "user_id" ], name: "index_event_attendees_on_user_id"
    end

    # Foreign Keys
    add_foreign_key "events", "users", column: "creator_id"
    add_foreign_key "event_attendees", "events"
    add_foreign_key "event_attendees", "users"
    add_foreign_key "event_attendees", "payments"
  end
end
