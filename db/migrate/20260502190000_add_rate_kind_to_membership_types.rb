# frozen_string_literal: true

class AddRateKindToMembershipTypes < ActiveRecord::Migration[8.1]
  def up
    add_column :membership_types, :rate_kind, :string, null: false, default: "standard"
    add_index :membership_types, :rate_kind

    execute <<~SQL.squish
      UPDATE membership_types
      SET rate_kind = 'reduced'
      WHERE name IN ('Adhésion Cirque Réduite', 'Adhésion Cirque Tarif Réduit')
    SQL
  end

  def down
    remove_index :membership_types, :rate_kind
    remove_column :membership_types, :rate_kind
  end
end
