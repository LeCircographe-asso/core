# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_05_04_120000) do
  create_table "action_cable_channels", force: :cascade do |t|
    t.string "channel_name", null: false
    t.string "connection_identifier", null: false
    t.datetime "created_at", null: false
    t.datetime "last_seen_at", null: false
    t.datetime "updated_at", null: false
    t.index ["channel_name", "connection_identifier"], name: "index_action_cable_channels_unique", unique: true
    t.index ["last_seen_at"], name: "index_action_cable_channels_on_last_seen_at"
  end

  create_table "action_cable_streams", force: :cascade do |t|
    t.integer "action_cable_channel_id", null: false
    t.datetime "created_at", null: false
    t.string "stream_name", null: false
    t.datetime "updated_at", null: false
    t.index ["action_cable_channel_id", "stream_name"], name: "index_action_cable_streams_unique", unique: true
    t.index ["action_cable_channel_id"], name: "index_action_cable_streams_on_action_cable_channel_id"
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", limit: 1024, null: false
    t.integer "channel_hash", limit: 8, null: false
    t.datetime "created_at", null: false
    t.binary "payload", limit: 536870912, null: false
    t.index ["channel"], name: "index_solid_cable_messages_on_channel"
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end
end
