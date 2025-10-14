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

ActiveRecord::Schema[8.0].define(version: 2025_10_14_091726) do
  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "attendance_lists", force: :cascade do |t|
    t.datetime "start_date"
    t.datetime "end_date"
    t.integer "list_type"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
  end

  create_table "attendances", force: :cascade do |t|
    t.datetime "arrival_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "attendance_list_id"
    t.integer "user_id"
    t.integer "book_of_entry_id"
    t.datetime "deleted_at"
    t.integer "person_id"
    t.integer "event_id"
    t.date "date"
    t.index ["attendance_list_id"], name: "index_attendances_on_attendance_list_id"
    t.index ["book_of_entry_id"], name: "index_attendances_on_book_of_entry_id"
    t.index ["date"], name: "index_attendances_on_date"
    t.index ["deleted_at"], name: "index_attendances_on_deleted_at"
    t.index ["event_id"], name: "index_attendances_on_event_id"
    t.index ["person_id", "date"], name: "index_attendances_on_person_id_and_date", unique: true
    t.index ["person_id"], name: "index_attendances_on_person_id"
    t.index ["user_id"], name: "index_attendances_on_user_id"
  end

  create_table "blogs", force: :cascade do |t|
    t.string "title"
    t.string "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "book_of_entries", force: :cascade do |t|
    t.integer "product_id"
    t.integer "user_id"
    t.integer "remaining"
    t.integer "total_entry"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status"
    t.datetime "deleted_at"
    t.integer "person_id"
    t.integer "subscription_plan_id"
    t.integer "sessions_remaining", default: 0
    t.datetime "purchased_at"
    t.datetime "expires_at"
    t.index ["deleted_at"], name: "index_book_of_entries_on_deleted_at"
    t.index ["person_id", "status"], name: "index_book_of_entries_on_person_id_and_status"
    t.index ["person_id"], name: "index_book_of_entries_on_person_id"
    t.index ["product_id"], name: "index_book_of_entries_on_product_id"
    t.index ["purchased_at", "expires_at"], name: "index_book_of_entries_on_purchased_at_and_expires_at"
    t.index ["status"], name: "index_book_of_entries_on_status"
    t.index ["subscription_plan_id"], name: "index_book_of_entries_on_subscription_plan_id"
    t.index ["user_id"], name: "index_book_of_entries_on_user_id"
  end

  create_table "event_attendees", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "event_id", null: false
    t.integer "payment_id"
    t.boolean "interested", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_event_attendees_on_event_id"
    t.index ["payment_id"], name: "index_event_attendees_on_payment_id"
    t.index ["user_id"], name: "index_event_attendees_on_user_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "name", null: false
    t.text "upper_description"
    t.text "middle_description"
    t.text "bottom_description"
    t.string "location"
    t.datetime "date", null: false
    t.integer "creator_id", null: false
    t.string "picture_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "category", default: 0
    t.text "description"
    t.index ["category"], name: "index_events_on_category"
    t.index ["creator_id"], name: "index_events_on_creator_id"
    t.index ["date"], name: "index_events_on_date"
  end

  create_table "membership_types", force: :cascade do |t|
    t.string "name", null: false
    t.integer "category", null: false
    t.integer "price_cents", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_membership_types_on_category"
    t.index ["name"], name: "index_membership_types_on_name", unique: true
  end

  create_table "memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "person_id"
    t.integer "membership_type_id"
    t.date "started_at"
    t.date "ended_at"
    t.integer "status", default: 1
    t.date "first_joined_at"
    t.index ["membership_type_id"], name: "index_memberships_on_membership_type_id"
    t.index ["person_id", "status"], name: "index_memberships_on_person_id_and_status"
    t.index ["person_id"], name: "index_memberships_on_person_id"
    t.index ["started_at", "ended_at"], name: "index_memberships_on_started_at_and_ended_at"
    t.index ["status"], name: "index_memberships_on_status"
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
    t.decimal "donation"
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_orders_on_deleted_at"
    t.index ["donation"], name: "index_orders_on_donation"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "payment_audit_logs", force: :cascade do |t|
    t.integer "payment_id", null: false
    t.integer "user_id"
    t.string "action", null: false
    t.text "change_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action"], name: "index_payment_audit_logs_on_action"
    t.index ["created_at"], name: "index_payment_audit_logs_on_created_at"
    t.index ["payment_id"], name: "index_payment_audit_logs_on_payment_id"
    t.index ["user_id"], name: "index_payment_audit_logs_on_user_id"
  end

  create_table "payment_lines", force: :cascade do |t|
    t.integer "payment_id", null: false
    t.string "item_type", null: false
    t.bigint "item_id", null: false
    t.integer "amount_cents", null: false
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_type", "item_id"], name: "index_payment_lines_on_item_type_and_item_id"
    t.index ["payment_id", "item_type", "item_id"], name: "index_payment_lines_unique_item", unique: true
    t.index ["payment_id"], name: "index_payment_lines_on_payment_id"
  end

  create_table "payments", force: :cascade do |t|
    t.datetime "payment_date"
    t.decimal "total_cents"
    t.integer "payment_type"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.integer "order_id"
    t.decimal "donation"
    t.decimal "total_payment"
    t.datetime "deleted_at"
    t.string "uuid"
    t.integer "person_id"
    t.integer "recorded_by_id"
    t.integer "payment_method", default: 0
    t.text "notes"
    t.index ["deleted_at"], name: "index_payments_on_deleted_at"
    t.index ["order_id"], name: "index_payments_on_order_id"
    t.index ["payment_date"], name: "index_payments_on_payment_date"
    t.index ["payment_method"], name: "index_payments_on_payment_method"
    t.index ["person_id", "payment_method"], name: "index_payments_on_person_id_and_payment_method"
    t.index ["person_id"], name: "index_payments_on_person_id"
    t.index ["recorded_by_id"], name: "index_payments_on_recorded_by_id"
    t.index ["status"], name: "index_payments_on_status"
    t.index ["total_cents"], name: "index_payments_on_total_cents"
    t.index ["user_id"], name: "index_payments_on_user_id"
    t.index ["uuid"], name: "index_payments_on_uuid", unique: true
  end

  create_table "people", force: :cascade do |t|
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "phone"
    t.string "email"
    t.text "address"
    t.date "birth_date"
    t.string "emergency_contact_name"
    t.string "emergency_contact_phone"
    t.text "notes"
    t.string "occupation"
    t.string "specialty"
    t.boolean "image_rights", default: false
    t.boolean "get_involved", default: false
    t.boolean "newsletter_subscribed", default: false
    t.boolean "dyslexic_font", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_people_on_email", unique: true
    t.index ["first_name", "last_name"], name: "index_people_on_first_name_and_last_name"
    t.index ["phone"], name: "index_people_on_phone"
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
    t.string "product_type"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "subscription_plans", force: :cascade do |t|
    t.string "name", null: false
    t.integer "duration", null: false
    t.integer "price_cents", null: false
    t.text "description"
    t.integer "sessions_count"
    t.integer "validity_days"
    t.integer "membership_type_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["duration"], name: "index_subscription_plans_on_duration"
    t.index ["membership_type_id"], name: "index_subscription_plans_on_membership_type_id"
    t.index ["name"], name: "index_subscription_plans_on_name", unique: true
  end

  create_table "tag_blogs", force: :cascade do |t|
    t.integer "tag_id", null: false
    t.integer "blog_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["blog_id"], name: "index_tag_blogs_on_blog_id"
    t.index ["tag_id"], name: "index_tag_blogs_on_tag_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_memberships", force: :cascade do |t|
    t.date "start_date"
    t.date "end_date"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "membership_id", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_user_memberships_on_deleted_at"
    t.index ["membership_id"], name: "index_user_memberships_on_membership_id"
    t.index ["user_id", "status"], name: "index_user_memberships_on_user_id_and_status"
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
    t.boolean "created_by_admin"
    t.boolean "dyslexic_font"
    t.string "full_name"
    t.boolean "deleted", default: false, null: false
    t.datetime "deleted_at"
    t.integer "person_id"
    t.index ["deleted"], name: "index_users_on_deleted"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["person_id"], name: "index_users_on_person_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "attendances", "attendance_lists"
  add_foreign_key "attendances", "book_of_entries"
  add_foreign_key "attendances", "events"
  add_foreign_key "attendances", "people"
  add_foreign_key "attendances", "users"
  add_foreign_key "book_of_entries", "people"
  add_foreign_key "book_of_entries", "products"
  add_foreign_key "book_of_entries", "subscription_plans"
  add_foreign_key "book_of_entries", "users"
  add_foreign_key "event_attendees", "events"
  add_foreign_key "event_attendees", "payments"
  add_foreign_key "event_attendees", "users"
  add_foreign_key "events", "users", column: "creator_id"
  add_foreign_key "memberships", "membership_types"
  add_foreign_key "memberships", "people"
  add_foreign_key "orders", "users"
  add_foreign_key "payment_audit_logs", "payments"
  add_foreign_key "payment_audit_logs", "users"
  add_foreign_key "payment_lines", "payments"
  add_foreign_key "payments", "people"
  add_foreign_key "payments", "users"
  add_foreign_key "payments", "users", column: "recorded_by_id"
  add_foreign_key "price_entries", "price_catalogs"
  add_foreign_key "price_entries", "products"
  add_foreign_key "product_orders", "orders"
  add_foreign_key "product_orders", "products"
  add_foreign_key "product_orders", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "subscription_plans", "membership_types"
  add_foreign_key "tag_blogs", "blogs"
  add_foreign_key "tag_blogs", "tags"
  add_foreign_key "user_memberships", "memberships"
  add_foreign_key "user_memberships", "users"
  add_foreign_key "users", "people"
end
