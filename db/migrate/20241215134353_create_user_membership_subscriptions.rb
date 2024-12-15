class CreateUserMembershipSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :user_membership_subscriptions do |t|
      t.references :user_membership, null: false, foreign_key: true
      t.references :subscription_type, null: false, foreign_key: true

      t.timestamps
    end
  end
end
