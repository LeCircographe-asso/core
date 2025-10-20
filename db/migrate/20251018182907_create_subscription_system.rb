class CreateSubscriptionSystem < ActiveRecord::Migration[8.0]
  def change
    # Subscription System
    create_table "subscription_plans", force: :cascade do |t|
      t.string "name", null: false
      t.integer "duration", null: false
      t.integer "price_cents", null: false
      t.text "description"
      t.integer "sessions_count"
      t.integer "validity_days"
      t.bigint "membership_type_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["duration"], name: "index_subscription_plans_on_duration"
      t.index ["membership_type_id"], name: "index_subscription_plans_on_membership_type_id"
      t.index ["name"], name: "index_subscription_plans_on_name", unique: true
    end

    create_table "book_of_entries", force: :cascade do |t|
      t.bigint "person_id", null: false
      t.bigint "subscription_plan_id", null: false
      t.integer "sessions_remaining", default: 0
      t.datetime "purchased_at", null: false
      t.datetime "expires_at", null: false
      t.integer "status", default: 0, null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["person_id", "status"], name: "index_book_of_entries_on_person_id_and_status"
      t.index ["person_id"], name: "index_book_of_entries_on_person_id"
      t.index ["purchased_at", "expires_at"], name: "index_book_of_entries_on_purchased_at_and_expires_at"
      t.index ["status"], name: "index_book_of_entries_on_status"
      t.index ["subscription_plan_id"], name: "index_book_of_entries_on_subscription_plan_id"
    end

    # Foreign Keys
    add_foreign_key "subscription_plans", "membership_types"
    add_foreign_key "book_of_entries", "people"
    add_foreign_key "book_of_entries", "subscription_plans"
  end
end
