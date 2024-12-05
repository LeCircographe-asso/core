class CreateUserMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table :user_memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :subscription_type, null: false, foreign_key: true
      t.references :payment, foreign_key: true
      t.boolean :status

      t.timestamps
    end
  end
end
