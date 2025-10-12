class CreatePaymentAuditLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :payment_audit_logs do |t|
      t.references :payment, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true
      t.string :action, null: false
      t.text :change_data
      t.timestamps
    end

    add_index :payment_audit_logs, :action
    add_index :payment_audit_logs, :created_at
  end
end
