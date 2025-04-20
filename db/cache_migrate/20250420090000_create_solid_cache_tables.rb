class CreateSolidCacheTables < ActiveRecord::Migration[8.0]
  def change
    create_table :solid_cache_entries, if_not_exists: true do |t|
      t.binary :key, null: false
      t.binary :value, null: false
      t.datetime :created_at, null: false
      t.datetime :expires_at, null: true
    end

    add_index :solid_cache_entries, :key, unique: true, if_not_exists: true
    add_index :solid_cache_entries, :expires_at, if_not_exists: true
  end
end
