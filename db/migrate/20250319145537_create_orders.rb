class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.decimal :sum
      t.date :date
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
