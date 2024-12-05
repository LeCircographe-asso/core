class CreateSubscriptionTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :subscription_types do |t|
      t.decimal :price
      t.integer :duration
      t.text :description
      t.string :name

      t.timestamps
    end
  end
end
