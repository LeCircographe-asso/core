class CreateMembershipSystem < ActiveRecord::Migration[8.0]
  def change
    # Membership System
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
      t.bigint "person_id", null: false
      t.bigint "membership_type_id", null: false
      t.date "started_at", null: false
      t.date "ended_at", null: false
      t.integer "status", default: 1, null: false
      t.date "first_joined_at"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["membership_type_id"], name: "index_memberships_on_membership_type_id"
      t.index ["person_id", "status"], name: "index_memberships_on_person_id_and_status"
      t.index ["person_id"], name: "index_memberships_on_person_id"
      t.index ["started_at", "ended_at"], name: "index_memberships_on_started_at_and_ended_at"
      t.index ["status"], name: "index_memberships_on_status"
    end

    # Foreign Keys
    add_foreign_key "memberships", "people"
    add_foreign_key "memberships", "membership_types"
  end
end
