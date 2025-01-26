class CreateUserMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table :user_memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :subscription_type, null: false, foreign_key: true
      t.references :payment, foreign_key: true
      t.string :status, default: 'pending', null: false
      t.datetime :start_date
      t.datetime :end_date
      t.integer :remaining_sessions
      t.integer :renewal_count, default: 0
      t.integer :year_reference  # Pour faciliter les stats par année scolaire

      t.timestamps

      t.index :status
      t.index [:user_id, :subscription_type_id, :status], 
              name: 'index_user_memberships_on_user_sub_status'
      t.index :year_reference
      t.index :start_date
      t.index :end_date
    end
  end
end
