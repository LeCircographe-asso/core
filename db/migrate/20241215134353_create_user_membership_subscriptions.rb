class CreateUserMembershipSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :user_membership_subscriptions do |t|
      t.references :user_membership, null: false, foreign_key: true
      t.references :subscription_type, null: false, foreign_key: true
      t.references :payment, null: false, foreign_key: true
      t.datetime :start_date, null: false
      t.datetime :end_date
      t.integer :remaining_sessions
      t.integer :status, default: 0, null: false
      t.integer :subscription_priority, default: 0, null: false

      t.timestamps

      t.index :start_date
      t.index :end_date
      t.index :status
      t.index :subscription_priority
      t.index [:user_membership_id, :status], name: 'index_user_membership_subs_on_membership_and_status'
    end
  end
end
