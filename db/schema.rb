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

ActiveRecord::Schema[8.0].define(version: 2024_12_15_151614) do
  create_table "donations", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "payment_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["payment_id"], name: "index_donations_on_payment_id"
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
    t.string "payment_method"
    t.decimal "amount"
    t.boolean "status", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
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
    t.decimal "price"
    t.integer "duration"
    t.text "description"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "training_attendees", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "user_membership_id", null: false
    t.boolean "check"
    t.text "comments"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_training_attendees_on_user_id"
    t.index ["user_membership_id"], name: "index_training_attendees_on_user_membership_id"
  end

  create_table "user_membership_subscriptions", force: :cascade do |t|
    t.integer "user_membership_id", null: false
    t.integer "subscription_type_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["subscription_type_id"], name: "index_user_membership_subscriptions_on_subscription_type_id"
    t.index ["user_membership_id"], name: "index_user_membership_subscriptions_on_user_membership_id"
  end

  create_table "user_memberships", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "subscription_type_id", null: false
    t.integer "payment_id"
    t.boolean "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "expiration_date"
    t.index ["payment_id"], name: "index_user_memberships_on_payment_id"
    t.index ["subscription_type_id"], name: "index_user_memberships_on_subscription_type_id"
    t.index ["user_id"], name: "index_user_memberships_on_user_id"
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
    t.integer "role", default: 0
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
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "donations", "payments"
  add_foreign_key "donations", "users"
  add_foreign_key "event_attendees", "events"
  add_foreign_key "event_attendees", "payments"
  add_foreign_key "event_attendees", "users"
  add_foreign_key "events", "users", column: "creator_id"
  add_foreign_key "payments", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "training_attendees", "user_memberships"
  add_foreign_key "training_attendees", "users"
  add_foreign_key "user_membership_subscriptions", "subscription_types"
  add_foreign_key "user_membership_subscriptions", "user_memberships"
  add_foreign_key "user_memberships", "payments"
  add_foreign_key "user_memberships", "subscription_types"
  add_foreign_key "user_memberships", "users"
  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
end
