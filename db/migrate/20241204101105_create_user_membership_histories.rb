class CreateUserMembershipHistories < ActiveRecord::Migration[8.0]
  def up
    create_table :user_membership_histories do |t|
      t.references :user_membership, null: false, foreign_key: true
      t.string :change_type, null: false  # creation, renewal, cancellation, status_change
      t.string :old_status
      t.string :new_status
      t.datetime :old_start_date
      t.datetime :old_end_date
      t.datetime :new_start_date
      t.datetime :new_end_date
      t.integer :old_remaining_sessions
      t.integer :new_remaining_sessions
      t.text :change_reason
      t.references :changed_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    unless index_exists?(:user_membership_histories, :change_type)
      add_index :user_membership_histories, :change_type
    end
  end

  def down
    drop_table :user_membership_histories
  end
end 