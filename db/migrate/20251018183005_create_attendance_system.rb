class CreateAttendanceSystem < ActiveRecord::Migration[8.0]
  def change
    # Attendance System
    create_table "attendance_lists", force: :cascade do |t|
      t.datetime "start_date"
      t.datetime "end_date"
      t.integer "list_type"
      t.integer "status"
      t.string "name"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end

    create_table "attendances", force: :cascade do |t|
      t.bigint "person_id", null: false
      t.bigint "event_id"
      t.date "date", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index [ "person_id", "date" ], name: "index_attendances_on_person_id_and_date", unique: true
      t.index [ "person_id" ], name: "index_attendances_on_person_id"
      t.index [ "event_id" ], name: "index_attendances_on_event_id"
    end

    # Foreign Keys
    add_foreign_key "attendances", "people"
    add_foreign_key "attendances", "events"
  end
end
