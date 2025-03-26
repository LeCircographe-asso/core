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

ActiveRecord::Schema[8.0].define(version: 2025_03_25_145648) do
  create_table "attendance_lists", force: :cascade do |t|
    t.datetime "start_date"
    t.datetime "end_date"
    t.integer "list_type"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "attendances", force: :cascade do |t|
    t.datetime "arrival_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "attendance_list_id", null: false
    t.integer "user_id", null: false
    t.integer "book_of_entry_id"
    t.index ["attendance_list_id"], name: "index_attendances_on_attendance_list_id"
    t.index ["book_of_entry_id"], name: "index_attendances_on_book_of_entry_id"
    t.index ["user_id"], name: "index_attendances_on_user_id"
  end

  create_table "book_of_entries", force: :cascade do |t|
    t.integer "product_id", null: false
    t.integer "user_id", null: false
    t.integer "remaining"
    t.integer "total_entry"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status"
    t.index ["product_id"], name: "index_book_of_entries_on_product_id"
    t.index ["user_id"], name: "index_book_of_entries_on_user_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "title", null: false
    t.text "upper_description"
    t.text "middle_description"
    t.text "bottom_description"
    t.string "location"
    t.datetime "date", null: false
    t.integer "creator_id", null: false
    t.string "picture_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_events_on_creator_id"
  end

  create_table "memberships", force: :cascade do |t|
    t.integer "type_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "opening_hours", force: :cascade do |t|
    t.time "open_at", null: false
    t.time "close_at", null: false
    t.integer "day", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "orders", force: :cascade do |t|
    t.decimal "sum"
    t.date "date"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "product_order_id"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "payments", force: :cascade do |t|
    t.string "payment_method"
    t.decimal "amount"
    t.boolean "status", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "product_order_id", null: false
    t.index ["product_order_id"], name: "index_payments_on_product_order_id"
    t.index ["user_id"], name: "index_payments_on_user_id"
  end

  create_table "price_catalogs", force: :cascade do |t|
    t.boolean "active"
    t.decimal "price", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "price_entries", force: :cascade do |t|
    t.integer "product_id", null: false
    t.integer "price_catalog_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["price_catalog_id"], name: "index_price_entries_on_price_catalog_id"
    t.index ["product_id"], name: "index_price_entries_on_product_id"
  end

  create_table "product_orders", force: :cascade do |t|
    t.integer "product_id", null: false
    t.integer "order_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["order_id"], name: "index_product_orders_on_order_id"
    t.index ["product_id"], name: "index_product_orders_on_product_id"
    t.index ["user_id"], name: "index_product_orders_on_user_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "product_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "roles", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "user_memberships", force: :cascade do |t|
    t.date "start_date"
    t.date "end_date"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "membership_id", null: false
    t.index ["membership_id"], name: "index_user_memberships_on_membership_id"
    t.index ["user_id"], name: "index_user_memberships_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "last_name"
    t.string "first_name"
    t.date "birthdate"
    t.text "address"
    t.string "zip_code"
    t.text "town"
    t.string "country"
    t.string "phone_number"
    t.text "occupation"
    t.text "specialty"
    t.boolean "image_rights", default: false
    t.boolean "get_involved", default: false
    t.string "password_reset_token"
    t.datetime "password_reset_sent_at"
    t.integer "system_role", default: 3, null: false
    t.boolean "newsletter_subscribed"
    t.string "unsubscribe_token"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "attendances", "attendance_lists"
  add_foreign_key "attendances", "book_of_entries"
  add_foreign_key "attendances", "users"
  add_foreign_key "book_of_entries", "products"
  add_foreign_key "book_of_entries", "users"
  add_foreign_key "events", "users", column: "creator_id"
  add_foreign_key "orders", "product_orders"
  add_foreign_key "orders", "users"
  add_foreign_key "payments", "product_orders"
  add_foreign_key "payments", "users"
  add_foreign_key "price_entries", "price_catalogs"
  add_foreign_key "price_entries", "products"
  add_foreign_key "product_orders", "orders"
  add_foreign_key "product_orders", "products"
  add_foreign_key "product_orders", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "user_memberships", "memberships"
  add_foreign_key "user_memberships", "users"
end
