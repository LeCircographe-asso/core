# frozen_string_literal: true

class AddRateKindToContributionFormulas < ActiveRecord::Migration[8.1]
  def up
    add_column :contribution_formulas, :rate_kind, :string, null: false, default: "standard"
    add_index :contribution_formulas, :rate_kind

    execute <<~SQL.squish
      UPDATE contribution_formulas
      SET rate_kind = 'reduced'
      WHERE membership_type_id IN (
        SELECT id FROM membership_types WHERE rate_kind = 'reduced'
      )
    SQL
  end

  def down
    remove_index :contribution_formulas, :rate_kind
    remove_column :contribution_formulas, :rate_kind
  end
end
