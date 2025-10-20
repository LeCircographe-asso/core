class CreateAuditLogs < ActiveRecord::Migration[8.0]
  def change
    # Payment Audit Log
    create_table "payment_audit_logs", force: :cascade do |t|
      t.bigint "payment_id", null: false
      t.bigint "user_id"
      t.string "action", null: false
      t.text "change_data"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["action"], name: "index_payment_audit_logs_on_action"
      t.index ["created_at"], name: "index_payment_audit_logs_on_created_at"
      t.index ["payment_id"], name: "index_payment_audit_logs_on_payment_id"
      t.index ["user_id"], name: "index_payment_audit_logs_on_user_id"
    end

    # Foreign Keys
    add_foreign_key "payment_audit_logs", "payments"
    add_foreign_key "payment_audit_logs", "users"
  end
end
