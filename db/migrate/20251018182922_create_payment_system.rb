class CreatePaymentSystem < ActiveRecord::Migration[8.0]
  def change
    # Payment System
    create_table "payments", force: :cascade do |t|
      t.bigint "person_id", null: false
      t.bigint "recorded_by_id", null: false
      t.integer "total_cents", null: false
      t.integer "payment_method", default: 0, null: false
      t.integer "status", default: 0, null: false
      t.text "notes"
      t.string "uuid"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index [ "person_id", "payment_method" ], name: "index_payments_on_person_id_and_payment_method"
      t.index [ "person_id" ], name: "index_payments_on_person_id"
      t.index [ "recorded_by_id" ], name: "index_payments_on_recorded_by_id"
      t.index [ "status" ], name: "index_payments_on_status"
      t.index [ "uuid" ], name: "index_payments_on_uuid", unique: true
    end

    create_table "payment_lines", force: :cascade do |t|
      t.bigint "payment_id", null: false
      t.string "item_type", null: false
      t.bigint "item_id", null: false
      t.integer "amount_cents", null: false
      t.string "description"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index [ "item_type", "item_id" ], name: "index_payment_lines_on_item_type_and_item_id"
      t.index [ "payment_id", "item_type", "item_id" ], name: "index_payment_lines_unique_item", unique: true
      t.index [ "payment_id" ], name: "index_payment_lines_on_payment_id"
    end

    # Foreign Keys
    add_foreign_key "payments", "people"
    add_foreign_key "payments", "users", column: "recorded_by_id"
    add_foreign_key "payment_lines", "payments"
  end
end
