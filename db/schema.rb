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

ActiveRecord::Schema[8.0].define(version: 2025_02_09_181820) do
  create_table "attendance_statistics", force: :cascade do |t|
    t.string "period_type", null: false
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.integer "total_visits", default: 0
    t.integer "unique_visitors", default: 0
    t.integer "visitor_count", default: 0
    t.integer "peak_attendance"
    t.datetime "peak_time"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["period_type", "start_date"], name: "index_attendance_statistics_on_period_type_and_start_date", unique: true
    t.index ["period_type"], name: "index_attendance_statistics_on_period_type"
    t.index ["start_date"], name: "index_attendance_statistics_on_start_date"
  end

  create_table "donations", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "payment_id", null: false
    t.decimal "amount", precision: 8, scale: 2, null: false
    t.text "notes"
    t.string "status", default: "pending", null: false
    t.integer "processed_by_id"
    t.datetime "processed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["payment_id"], name: "index_donations_on_payment_id"
    t.index ["processed_at"], name: "index_donations_on_processed_at"
    t.index ["processed_by_id"], name: "index_donations_on_processed_by_id"
    t.index ["status"], name: "index_donations_on_status"
    t.index ["user_id"], name: "index_donations_on_user_id"
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

  create_table "payments", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "payment_method", null: false
    t.decimal "amount", precision: 8, scale: 2, null: false
    t.decimal "donation_amount", precision: 8, scale: 2, default: "0.0"
    t.string "status", default: "pending", null: false
    t.integer "processed_by_id"
    t.datetime "processed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["payment_method"], name: "index_payments_on_payment_method"
    t.index ["processed_at"], name: "index_payments_on_processed_at"
    t.index ["processed_by_id"], name: "index_payments_on_processed_by_id"
    t.index ["status"], name: "index_payments_on_status"
    t.index ["user_id"], name: "index_payments_on_user_id"
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

  create_table "subscription_types", force: :cascade do |t|
    t.string "name", null: false
    t.decimal "price", precision: 8, scale: 2, null: false
    t.text "description"
    t.integer "category", null: false
    t.string "duration_type", null: false
    t.integer "duration_value", null: false
    t.boolean "has_limited_sessions", default: false, null: false
    t.boolean "active", default: true, null: false
    t.date "valid_from", null: false
    t.date "valid_until"
    t.integer "year_reference"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_subscription_types_on_active"
    t.index ["category", "active"], name: "index_subscription_types_on_category_and_active"
    t.index ["category"], name: "index_subscription_types_on_category"
    t.index ["name"], name: "index_subscription_types_on_name", unique: true
    t.index ["valid_from"], name: "index_subscription_types_on_valid_from"
    t.index ["year_reference"], name: "index_subscription_types_on_year_reference"
  end

  create_table "training_attendees", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "training_session_id", null: false
    t.integer "user_membership_id", null: false
    t.integer "checked_by_id", null: false
    t.datetime "check_in_time", null: false
    t.boolean "is_visitor", default: false, null: false
    t.text "comments"
    t.string "attendance_type", default: "regular", null: false
    t.integer "year_reference"
    t.integer "week_number"
    t.integer "month_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["attendance_type"], name: "index_training_attendees_on_attendance_type"
    t.index ["check_in_time"], name: "index_training_attendees_on_check_in_time"
    t.index ["checked_by_id"], name: "index_training_attendees_on_checked_by_id"
    t.index ["month_number"], name: "index_training_attendees_on_month_number"
    t.index ["training_session_id"], name: "index_training_attendees_on_training_session_id"
    t.index ["user_id", "check_in_time"], name: "index_training_attendees_on_user_and_time", unique: true
    t.index ["user_id"], name: "index_training_attendees_on_user_id"
    t.index ["user_membership_id"], name: "index_training_attendees_on_user_membership_id"
    t.index ["week_number"], name: "index_training_attendees_on_week_number"
    t.index ["year_reference", "month_number"], name: "index_training_attendees_on_year_reference_and_month_number"
    t.index ["year_reference", "week_number"], name: "index_training_attendees_on_year_reference_and_week_number"
    t.index ["year_reference"], name: "index_training_attendees_on_year_reference"
  end

  create_table "training_sessions", force: :cascade do |t|
    t.date "date", null: false
    t.string "status", default: "open", null: false
    t.integer "recorded_by_id"
    t.text "notes"
    t.integer "year_reference"
    t.integer "week_number"
    t.integer "month_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_training_sessions_on_date", unique: true
    t.index ["month_number"], name: "index_training_sessions_on_month_number"
    t.index ["recorded_by_id"], name: "index_training_sessions_on_recorded_by_id"
    t.index ["status"], name: "index_training_sessions_on_status"
    t.index ["week_number"], name: "index_training_sessions_on_week_number"
    t.index ["year_reference", "month_number"], name: "index_training_sessions_on_year_reference_and_month_number"
    t.index ["year_reference", "week_number"], name: "index_training_sessions_on_year_reference_and_week_number"
    t.index ["year_reference"], name: "index_training_sessions_on_year_reference"
  end

  create_table "user_membership_histories", force: :cascade do |t|
    t.integer "user_membership_id", null: false
    t.string "change_type", null: false
    t.string "old_status"
    t.string "new_status"
    t.datetime "old_start_date"
    t.datetime "old_end_date"
    t.datetime "new_start_date"
    t.datetime "new_end_date"
    t.integer "old_remaining_sessions"
    t.integer "new_remaining_sessions"
    t.text "change_reason"
    t.integer "changed_by_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["change_type"], name: "index_user_membership_histories_on_change_type"
    t.index ["changed_by_id"], name: "index_user_membership_histories_on_changed_by_id"
    t.index ["user_membership_id"], name: "index_user_membership_histories_on_user_membership_id"
  end

  create_table "user_membership_subscriptions", force: :cascade do |t|
    t.integer "user_membership_id", null: false
    t.integer "subscription_type_id", null: false
    t.integer "payment_id", null: false
    t.datetime "start_date", null: false
    t.datetime "end_date"
    t.integer "remaining_sessions"
    t.string "status", default: "pending", null: false
    t.integer "subscription_priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["end_date"], name: "index_user_membership_subscriptions_on_end_date"
    t.index ["payment_id"], name: "index_user_membership_subscriptions_on_payment_id"
    t.index ["start_date"], name: "index_user_membership_subscriptions_on_start_date"
    t.index ["status"], name: "index_user_membership_subscriptions_on_status"
    t.index ["subscription_priority"], name: "index_user_membership_subscriptions_on_subscription_priority"
    t.index ["subscription_type_id"], name: "index_user_membership_subscriptions_on_subscription_type_id"
    t.index ["user_membership_id", "status"], name: "index_user_membership_subs_on_membership_and_status"
    t.index ["user_membership_id"], name: "index_user_membership_subscriptions_on_user_membership_id"
  end

  create_table "user_memberships", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "subscription_type_id", null: false
    t.integer "payment_id"
    t.string "status", default: "pending", null: false
    t.datetime "start_date"
    t.datetime "end_date"
    t.integer "remaining_sessions"
    t.integer "renewal_count", default: 0
    t.integer "year_reference"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "expiration_date"
    t.index ["end_date"], name: "index_user_memberships_on_end_date"
    t.index ["payment_id"], name: "index_user_memberships_on_payment_id"
    t.index ["start_date"], name: "index_user_memberships_on_start_date"
    t.index ["status"], name: "index_user_memberships_on_status"
    t.index ["subscription_type_id"], name: "index_user_memberships_on_subscription_type_id"
    t.index ["user_id", "subscription_type_id", "status"], name: "index_user_memberships_on_user_sub_status"
    t.index ["user_id"], name: "index_user_memberships_on_user_id"
    t.index ["year_reference"], name: "index_user_memberships_on_year_reference"
  end

  create_table "user_roles", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "role_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["user_id"], name: "index_user_roles_on_user_id"
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
    t.boolean "newsletter", default: false
    t.boolean "get_involved", default: false
    t.string "password_reset_token"
    t.datetime "password_reset_sent_at"
    t.integer "role", default: 0, null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "donations", "payments"
  add_foreign_key "donations", "users"
  add_foreign_key "donations", "users", column: "processed_by_id"
  add_foreign_key "event_attendees", "events"
  add_foreign_key "event_attendees", "payments"
  add_foreign_key "event_attendees", "users"
  add_foreign_key "events", "users", column: "creator_id"
  add_foreign_key "payments", "users"
  add_foreign_key "payments", "users", column: "processed_by_id"
  add_foreign_key "sessions", "users"
  add_foreign_key "training_attendees", "training_sessions"
  add_foreign_key "training_attendees", "user_memberships"
  add_foreign_key "training_attendees", "users"
  add_foreign_key "training_attendees", "users", column: "checked_by_id"
  add_foreign_key "training_sessions", "users", column: "recorded_by_id"
  add_foreign_key "user_membership_histories", "user_memberships"
  add_foreign_key "user_membership_histories", "users", column: "changed_by_id"
  add_foreign_key "user_membership_subscriptions", "payments"
  add_foreign_key "user_membership_subscriptions", "subscription_types"
  add_foreign_key "user_membership_subscriptions", "user_memberships"
  add_foreign_key "user_memberships", "payments"
  add_foreign_key "user_memberships", "subscription_types"
  add_foreign_key "user_memberships", "users"
  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
end
