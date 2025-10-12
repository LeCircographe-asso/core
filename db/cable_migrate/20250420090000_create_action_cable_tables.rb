class CreateActionCableTables < ActiveRecord::Migration[8.0]
  def change
    create_table :action_cable_channels, if_not_exists: true do |t|
      t.string :channel_name, null: false
      t.string :connection_identifier, null: false
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.datetime :last_seen_at, null: false
    end

    create_table :action_cable_streams, if_not_exists: true do |t|
      t.references :action_cable_channel, null: false
      t.string :stream_name, null: false
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end

    add_index :action_cable_channels, [ :channel_name, :connection_identifier ], unique: true, name: 'index_action_cable_channels_unique', if_not_exists: true
    add_index :action_cable_channels, :last_seen_at, if_not_exists: true

    add_index :action_cable_streams, [ :action_cable_channel_id, :stream_name ], unique: true, name: 'index_action_cable_streams_unique', if_not_exists: true
  end
end
