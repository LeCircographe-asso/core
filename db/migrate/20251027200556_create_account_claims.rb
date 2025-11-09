class CreateAccountClaims < ActiveRecord::Migration[8.1]
  def change
    create_table :account_claims do |t|
      t.references :person, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :confirmation_token, null: false
      t.string :status, default: "pending"
      t.datetime :expires_at, null: false
      t.timestamps
    end

    add_index :account_claims, :confirmation_token, unique: true
    add_index :account_claims, :status
  end
end
