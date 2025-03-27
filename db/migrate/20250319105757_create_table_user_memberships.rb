class CreateTableUserMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table :user_memberships do |t|
      t.date :start_date
      t.date :end_date
      t.integer :status
      t.timestamps
      t.references :user, null: false, foreign_key: true
      t.references :membership, null: false, foreign_key: true
    end
  end
end
