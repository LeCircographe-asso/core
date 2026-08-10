class CreatePriceChangeLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :price_change_logs do |t|
      t.references :loggable, polymorphic: true, null: false
      t.string  :action,      null: false
      t.text    :change_data
      t.bigint  :user_id

      t.timestamps
    end

    add_index :price_change_logs, :action
    add_index :price_change_logs, :user_id
  end
end
