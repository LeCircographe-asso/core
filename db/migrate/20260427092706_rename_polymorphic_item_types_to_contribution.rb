class RenamePolymorphicItemTypesToContribution < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE payment_lines
      SET item_type = 'ContributionFormula'
      WHERE item_type = 'SubscriptionPlan'
    SQL

    execute <<~SQL
      UPDATE payment_lines
      SET item_type = 'Contribution'
      WHERE item_type = 'BookOfEntry'
    SQL
  end

  def down
    execute <<~SQL
      UPDATE payment_lines
      SET item_type = 'BookOfEntry'
      WHERE item_type = 'Contribution'
    SQL

    execute <<~SQL
      UPDATE payment_lines
      SET item_type = 'SubscriptionPlan'
      WHERE item_type = 'ContributionFormula'
    SQL
  end
end
