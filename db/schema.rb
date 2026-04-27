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

ActiveRecord::Schema[8.1].define(version: 2026_04_27_084000) do
  create_table "account_claims", force: :cascade do |t|
    t.string "confirmation_token", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.integer "person_id", null: false
    t.string "status", default: "pending"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["confirmation_token"], name: "index_account_claims_on_confirmation_token", unique: true
    t.index ["person_id"], name: "index_account_claims_on_person_id"
    t.index ["status"], name: "index_account_claims_on_status"
    t.index ["user_id"], name: "index_account_claims_on_user_id"
  end

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "attendance_lists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "end_date"
    t.integer "list_type"
    t.string "name"
    t.datetime "start_date"
    t.integer "status"
    t.datetime "updated_at", null: false
  end

  create_table "attendances", force: :cascade do |t|
    t.integer "attendance_list_id"
    t.integer "book_of_entry_id"
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.bigint "event_id"
    t.bigint "person_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["event_id"], name: "index_attendances_on_event_id"
    t.index ["person_id", "date"], name: "index_attendances_on_person_id_and_date", unique: true
    t.index ["person_id"], name: "index_attendances_on_person_id"
  end

  create_table "blogs", force: :cascade do |t|
    t.string "content"
    t.datetime "created_at", null: false
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "book_of_entries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.bigint "person_id", null: false
    t.datetime "purchased_at", null: false
    t.integer "sessions_remaining"
    t.integer "status", default: 0, null: false
    t.bigint "subscription_plan_id", null: false
    t.datetime "suspended_at"
    t.text "suspended_reason"
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_book_of_entries_on_expires_at"
    t.index ["person_id", "status", "expires_at"], name: "idx_boe_person_status_exp"
    t.index ["person_id", "status"], name: "index_book_of_entries_on_person_id_and_status"
    t.index ["person_id"], name: "index_book_of_entries_on_person_id"
    t.index ["purchased_at", "expires_at"], name: "index_book_of_entries_on_purchased_at_and_expires_at"
    t.index ["status"], name: "index_book_of_entries_on_status"
    t.index ["subscription_plan_id"], name: "index_book_of_entries_on_subscription_plan_id"
  end

  create_table "event_attendees", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.boolean "interested"
    t.bigint "payment_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["event_id"], name: "index_event_attendees_on_event_id"
    t.index ["payment_id"], name: "index_event_attendees_on_payment_id"
    t.index ["user_id"], name: "index_event_attendees_on_user_id"
  end

  create_table "events", force: :cascade do |t|
    t.text "bottom_description"
    t.integer "category", default: 0
    t.datetime "created_at", null: false
    t.bigint "creator_id", null: false
    t.datetime "date", null: false
    t.text "description"
    t.string "location"
    t.text "middle_description"
    t.string "name", null: false
    t.string "picture_url"
    t.datetime "updated_at", null: false
    t.text "upper_description"
    t.index ["category"], name: "index_events_on_category"
    t.index ["creator_id"], name: "index_events_on_creator_id"
    t.index ["date"], name: "index_events_on_date"
  end

  create_table "member_number_histories", force: :cascade do |t|
    t.datetime "assigned_at", null: false
    t.datetime "created_at", null: false
    t.string "member_number", null: false
    t.string "membership_type", null: false
    t.text "notes"
    t.integer "person_id", null: false
    t.datetime "replaced_at"
    t.datetime "updated_at", null: false
    t.integer "year", null: false
    t.index ["member_number"], name: "index_member_number_histories_on_member_number", unique: true
    t.index ["person_id", "assigned_at"], name: "index_member_number_histories_on_person_id_and_assigned_at"
    t.index ["person_id"], name: "index_member_number_histories_on_person_id"
  end

  create_table "membership_types", force: :cascade do |t|
    t.integer "category", null: false
    t.text "change_reason"
    t.datetime "created_at", null: false
    t.integer "created_by_user_id"
    t.text "description"
    t.date "effective_from"
    t.date "effective_until"
    t.string "name", null: false
    t.integer "price_cents", null: false
    t.datetime "updated_at", null: false
    t.integer "version", default: 1, null: false
    t.index ["category"], name: "index_membership_types_on_category"
    t.index ["created_by_user_id"], name: "index_membership_types_on_created_by_user_id"
    t.index ["effective_from", "effective_until"], name: "idx_membership_types_effective_period"
    t.index ["name", "version"], name: "idx_membership_types_name_version", unique: true
  end

  create_table "memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "ended_at", null: false
    t.date "first_joined_at"
    t.bigint "membership_type_id", null: false
    t.bigint "person_id", null: false
    t.date "started_at", null: false
    t.integer "status", default: 1, null: false
    t.datetime "updated_at", null: false
    t.index ["membership_type_id", "status"], name: "idx_memberships_circus_active"
    t.index ["membership_type_id"], name: "index_memberships_on_membership_type_id"
    t.index ["person_id", "status"], name: "index_memberships_on_person_id_and_status"
    t.index ["person_id"], name: "index_memberships_on_person_id"
    t.index ["started_at", "ended_at"], name: "index_memberships_on_started_at_and_ended_at"
    t.index ["status"], name: "index_memberships_on_status"
  end

  create_table "newsletter_subscribers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.text "notes"
    t.bigint "person_id"
    t.string "source"
    t.boolean "subscribed", default: true, null: false
    t.datetime "subscribed_at"
    t.string "unsubscribe_token"
    t.datetime "unsubscribed_at"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_newsletter_subscribers_on_email", unique: true
    t.index ["person_id"], name: "index_newsletter_subscribers_on_person_id"
    t.index ["subscribed", "email"], name: "index_newsletter_subscribers_on_subscribed_and_email"
    t.index ["unsubscribe_token"], name: "index_newsletter_subscribers_on_unsubscribe_token", unique: true
  end

  create_table "opening_hours", force: :cascade do |t|
    t.time "close_at", null: false
    t.datetime "created_at", null: false
    t.integer "day", null: false
    t.time "open_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "payment_audit_logs", force: :cascade do |t|
    t.string "action", null: false
    t.text "change_data"
    t.datetime "created_at", null: false
    t.bigint "payment_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["action"], name: "index_payment_audit_logs_on_action"
    t.index ["created_at"], name: "index_payment_audit_logs_on_created_at"
    t.index ["payment_id"], name: "index_payment_audit_logs_on_payment_id"
    t.index ["user_id"], name: "index_payment_audit_logs_on_user_id"
  end

  create_table "payment_lines", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.datetime "created_at", null: false
    t.string "description"
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.bigint "payment_id", null: false
    t.datetime "updated_at", null: false
    t.index ["amount_cents"], name: "idx_payment_lines_amount"
    t.index ["item_type", "item_id"], name: "index_payment_lines_on_item_type_and_item_id"
    t.index ["payment_id", "item_type", "item_id"], name: "index_payment_lines_unique_item", unique: true
    t.index ["payment_id"], name: "index_payment_lines_on_payment_id"
  end

  create_table "payments", force: :cascade do |t|
    t.datetime "anonymized_at"
    t.datetime "created_at", null: false
    t.text "notes"
    t.string "original_person_identifier"
    t.integer "payment_method", default: 0, null: false
    t.bigint "person_id", null: false
    t.bigint "recorded_by_id", null: false
    t.integer "status", default: 0, null: false
    t.integer "total_cents", null: false
    t.datetime "updated_at", null: false
    t.string "uuid"
    t.index ["anonymized_at"], name: "index_payments_on_anonymized_at"
    t.index ["person_id", "payment_method"], name: "index_payments_on_person_id_and_payment_method"
    t.index ["person_id"], name: "index_payments_on_person_id"
    t.index ["recorded_by_id"], name: "index_payments_on_recorded_by_id"
    t.index ["status", "created_at"], name: "idx_payments_status_created"
    t.index ["status"], name: "index_payments_on_status"
    t.index ["uuid"], name: "index_payments_on_uuid", unique: true
  end

  create_table "people", force: :cascade do |t|
    t.text "address"
    t.date "birth_date"
    t.string "country"
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.boolean "dyslexic_font"
    t.string "email"
    t.string "emergency_contact_name"
    t.string "emergency_contact_phone"
    t.string "first_name", null: false
    t.boolean "get_involved"
    t.boolean "image_rights"
    t.boolean "is_minor", null: false
    t.string "last_name", null: false
    t.string "member_number"
    t.boolean "newsletter_subscribed"
    t.string "newsletter_unsubscribe_token"
    t.text "notes"
    t.string "occupation"
    t.string "phone"
    t.boolean "reduced_rate_eligible", default: false, null: false
    t.string "reduced_rate_proof"
    t.string "reduced_rate_reason"
    t.string "specialty"
    t.string "town"
    t.datetime "updated_at", null: false
    t.string "zip_code"
    t.index ["deleted_at"], name: "index_people_on_deleted_at"
    t.index ["email"], name: "index_people_on_email", unique: true, where: "email IS NOT NULL AND email != ''"
    t.index ["first_name", "last_name"], name: "index_people_on_first_name_and_last_name"
    t.index ["member_number"], name: "index_people_on_member_number", unique: true
    t.index ["newsletter_unsubscribe_token"], name: "index_people_on_newsletter_unsubscribe_token", unique: true
    t.index ["phone"], name: "index_people_on_phone"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "subscription_plans", force: :cascade do |t|
    t.text "change_reason"
    t.datetime "created_at", null: false
    t.integer "created_by_user_id"
    t.text "description"
    t.integer "duration", null: false
    t.date "effective_from"
    t.date "effective_until"
    t.bigint "membership_type_id", null: false
    t.string "name", null: false
    t.integer "price_cents", null: false
    t.integer "sessions_count"
    t.datetime "updated_at", null: false
    t.integer "validity_days"
    t.integer "version", default: 1, null: false
    t.index ["created_by_user_id"], name: "index_subscription_plans_on_created_by_user_id"
    t.index ["duration"], name: "index_subscription_plans_on_duration"
    t.index ["effective_from", "effective_until"], name: "idx_subscription_plans_effective_period"
    t.index ["membership_type_id", "duration"], name: "idx_sub_plans_type_duration"
    t.index ["membership_type_id"], name: "index_subscription_plans_on_membership_type_id"
    t.index ["name", "version"], name: "idx_subscription_plans_name_version", unique: true
  end

  create_table "tag_blogs", force: :cascade do |t|
    t.bigint "blog_id", null: false
    t.datetime "created_at", null: false
    t.bigint "tag_id", null: false
    t.datetime "updated_at", null: false
    t.index ["blog_id"], name: "index_tag_blogs_on_blog_id"
    t.index ["tag_id"], name: "index_tag_blogs_on_tag_id"
  end

  create_table "tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "created_by_admin"
    t.boolean "deleted"
    t.datetime "deleted_at"
    t.string "email_address"
    t.string "password_digest", null: false
    t.datetime "password_reset_sent_at"
    t.string "password_reset_token"
    t.string "password_salt"
    t.bigint "person_id"
    t.integer "system_role", default: 3, null: false
    t.datetime "updated_at", null: false
    t.index ["deleted"], name: "index_users_on_deleted"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["person_id"], name: "index_users_on_person_id"
    t.index ["system_role"], name: "index_users_on_system_role"
  end

  add_foreign_key "account_claims", "people"
  add_foreign_key "account_claims", "users"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "attendances", "events"
  add_foreign_key "attendances", "people"
  add_foreign_key "book_of_entries", "people"
  add_foreign_key "book_of_entries", "subscription_plans"
  add_foreign_key "event_attendees", "events"
  add_foreign_key "event_attendees", "payments"
  add_foreign_key "event_attendees", "users"
  add_foreign_key "events", "users", column: "creator_id"
  add_foreign_key "member_number_histories", "people"
  add_foreign_key "membership_types", "users", column: "created_by_user_id"
  add_foreign_key "memberships", "membership_types"
  add_foreign_key "memberships", "people"
  add_foreign_key "newsletter_subscribers", "people", on_delete: :nullify
  add_foreign_key "payment_audit_logs", "payments"
  add_foreign_key "payment_audit_logs", "users"
  add_foreign_key "payment_lines", "payments"
  add_foreign_key "payments", "people"
  add_foreign_key "payments", "users", column: "recorded_by_id"
  add_foreign_key "sessions", "users"
  add_foreign_key "subscription_plans", "membership_types"
  add_foreign_key "subscription_plans", "users", column: "created_by_user_id"
  add_foreign_key "tag_blogs", "blogs"
  add_foreign_key "tag_blogs", "tags"
  add_foreign_key "users", "people"
end
