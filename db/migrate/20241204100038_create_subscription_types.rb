class CreateSubscriptionTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :subscription_types do |t|
      t.string :name, null: false
      t.decimal :price, precision: 8, scale: 2, null: false
      t.text :description
      t.integer :category, null: false
      t.string :duration_type, null: false
      t.integer :duration_value, null: false
      t.boolean :has_limited_sessions, default: false, null: false
      t.boolean :active, default: true, null: false
      t.date :valid_from, null: false
      t.date :valid_until
      t.integer :year_reference  # Pour faciliter les stats par année scolaire

      t.timestamps

      t.index :name, unique: true
      t.index :category
      t.index :active
      t.index [:category, :active]
      t.index :valid_from
      t.index :year_reference
    end
  end
end
