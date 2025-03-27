class DropUnusedTables < ActiveRecord::Migration[8.0]
  def change
    drop_table :donations
    drop_table :user_memberships
    drop_table :payments
    drop_table :roles
    drop_table :subscription_types
    drop_table :training_attendees
    drop_table :user_membership_subscriptions
    drop_table :user_roles
  end
end
