# frozen_string_literal: true

class AddPersonToPaymentLines < ActiveRecord::Migration[8.1]
  def up
    add_reference :payment_lines, :person, null: true, foreign_key: true, index: true

    say_with_time "Backfilling payment_lines.person_id" do
      # Ligne de cotisation : le bénéficiaire est le propriétaire de la Contribution.
      execute <<~SQL
        UPDATE payment_lines
        SET person_id = (
          SELECT contributions.person_id FROM contributions WHERE contributions.id = payment_lines.item_id
        )
        WHERE item_type = 'Contribution'
      SQL

      # Tout le reste (Membership, MembershipType, ContributionFormula, Donation, MembershipUpgrade) :
      # statu quo actuel, le payeur est aussi le bénéficiaire.
      execute <<~SQL
        UPDATE payment_lines
        SET person_id = (
          SELECT payments.person_id FROM payments WHERE payments.id = payment_lines.payment_id
        )
        WHERE person_id IS NULL
      SQL
    end
  end

  def down
    remove_reference :payment_lines, :person, foreign_key: true
  end
end
