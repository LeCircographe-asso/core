class AddPerformanceIndexes < ActiveRecord::Migration[8.0]
  def change
    # Performance improvements for dashboards and reports
    add_index :payments, [ :status, :created_at ], name: 'idx_payments_status_created'
    add_index :memberships, [ :membership_type_id, :status ], name: 'idx_memberships_circus_active'
    add_index :payment_lines, :amount_cents, name: 'idx_payment_lines_amount'
    add_index :book_of_entries, [ :person_id, :status, :expires_at ], name: 'idx_boe_person_status_exp'
    add_index :subscription_plans, [ :membership_type_id, :duration ], name: 'idx_sub_plans_type_duration'
  end
end
