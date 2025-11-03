class AddReducedRateToPeople < ActiveRecord::Migration[8.0]
  def change
    add_column :people, :reduced_rate_eligible, :boolean, default: false, null: false
    add_column :people, :reduced_rate_reason, :string
    add_column :people, :reduced_rate_proof, :string
  end
end
