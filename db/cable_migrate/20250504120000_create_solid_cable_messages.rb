# frozen_string_literal: true

class CreateSolidCableMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :solid_cable_messages, if_not_exists: true do |t|
      t.binary :channel, limit: 1024, null: false
      t.integer :channel_hash, limit: 8, null: false
      t.datetime :created_at, null: false
      t.binary :payload, limit: 536_870_912, null: false
    end

    add_index :solid_cable_messages, :channel, if_not_exists: true
    add_index :solid_cable_messages, :channel_hash, if_not_exists: true
    add_index :solid_cable_messages, :created_at, if_not_exists: true
  end
end
