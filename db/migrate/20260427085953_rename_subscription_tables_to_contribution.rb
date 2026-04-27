class RenameSubscriptionTablesToContribution < ActiveRecord::Migration[8.1]
  def up
    rename_table :subscription_plans, :contribution_formulas
    rename_table :book_of_entries, :contributions

    rename_column :contributions, :subscription_plan_id, :contribution_formula_id
    rename_column :attendances, :book_of_entry_id, :contribution_id

    rename_index :contributions, "index_book_of_entries_on_subscription_plan_id", "index_contributions_on_contribution_formula_id" if index_name_exists?(:contributions, "index_book_of_entries_on_subscription_plan_id")
    rename_index :contributions, "index_book_of_entries_on_expires_at", "index_contributions_on_expires_at" if index_name_exists?(:contributions, "index_book_of_entries_on_expires_at")
    rename_index :contributions, "index_book_of_entries_on_person_id", "index_contributions_on_person_id" if index_name_exists?(:contributions, "index_book_of_entries_on_person_id")
    rename_index :contributions, "index_book_of_entries_on_person_id_and_status", "index_contributions_on_person_id_and_status" if index_name_exists?(:contributions, "index_book_of_entries_on_person_id_and_status")
    rename_index :contributions, "index_book_of_entries_on_status", "index_contributions_on_status" if index_name_exists?(:contributions, "index_book_of_entries_on_status")
    rename_index :contributions, "index_book_of_entries_on_purchased_at_and_expires_at", "index_contributions_on_purchased_at_and_expires_at" if index_name_exists?(:contributions, "index_book_of_entries_on_purchased_at_and_expires_at")
    rename_index :contributions, "idx_boe_person_status_exp", "idx_contributions_person_status_exp" if index_name_exists?(:contributions, "idx_boe_person_status_exp")

    rename_index :contribution_formulas, "index_subscription_plans_on_created_by_user_id", "index_contribution_formulas_on_created_by_user_id" if index_name_exists?(:contribution_formulas, "index_subscription_plans_on_created_by_user_id")
    rename_index :contribution_formulas, "index_subscription_plans_on_duration", "index_contribution_formulas_on_duration" if index_name_exists?(:contribution_formulas, "index_subscription_plans_on_duration")
    rename_index :contribution_formulas, "idx_subscription_plans_effective_period", "idx_contribution_formulas_effective_period" if index_name_exists?(:contribution_formulas, "idx_subscription_plans_effective_period")
    rename_index :contribution_formulas, "idx_sub_plans_type_duration", "idx_contribution_formulas_type_duration" if index_name_exists?(:contribution_formulas, "idx_sub_plans_type_duration")
    rename_index :contribution_formulas, "index_subscription_plans_on_membership_type_id", "index_contribution_formulas_on_membership_type_id" if index_name_exists?(:contribution_formulas, "index_subscription_plans_on_membership_type_id")
    rename_index :contribution_formulas, "idx_subscription_plans_name_version", "idx_contribution_formulas_name_version" if index_name_exists?(:contribution_formulas, "idx_subscription_plans_name_version")
  end

  def down
    rename_index :contribution_formulas, "idx_contribution_formulas_name_version", "idx_subscription_plans_name_version" if index_name_exists?(:contribution_formulas, "idx_contribution_formulas_name_version")
    rename_index :contribution_formulas, "index_contribution_formulas_on_membership_type_id", "index_subscription_plans_on_membership_type_id" if index_name_exists?(:contribution_formulas, "index_contribution_formulas_on_membership_type_id")
    rename_index :contribution_formulas, "idx_contribution_formulas_type_duration", "idx_sub_plans_type_duration" if index_name_exists?(:contribution_formulas, "idx_contribution_formulas_type_duration")
    rename_index :contribution_formulas, "idx_contribution_formulas_effective_period", "idx_subscription_plans_effective_period" if index_name_exists?(:contribution_formulas, "idx_contribution_formulas_effective_period")
    rename_index :contribution_formulas, "index_contribution_formulas_on_duration", "index_subscription_plans_on_duration" if index_name_exists?(:contribution_formulas, "index_contribution_formulas_on_duration")
    rename_index :contribution_formulas, "index_contribution_formulas_on_created_by_user_id", "index_subscription_plans_on_created_by_user_id" if index_name_exists?(:contribution_formulas, "index_contribution_formulas_on_created_by_user_id")

    rename_index :contributions, "idx_contributions_person_status_exp", "idx_boe_person_status_exp" if index_name_exists?(:contributions, "idx_contributions_person_status_exp")
    rename_index :contributions, "index_contributions_on_purchased_at_and_expires_at", "index_book_of_entries_on_purchased_at_and_expires_at" if index_name_exists?(:contributions, "index_contributions_on_purchased_at_and_expires_at")
    rename_index :contributions, "index_contributions_on_status", "index_book_of_entries_on_status" if index_name_exists?(:contributions, "index_contributions_on_status")
    rename_index :contributions, "index_contributions_on_person_id_and_status", "index_book_of_entries_on_person_id_and_status" if index_name_exists?(:contributions, "index_contributions_on_person_id_and_status")
    rename_index :contributions, "index_contributions_on_person_id", "index_book_of_entries_on_person_id" if index_name_exists?(:contributions, "index_contributions_on_person_id")
    rename_index :contributions, "index_contributions_on_expires_at", "index_book_of_entries_on_expires_at" if index_name_exists?(:contributions, "index_contributions_on_expires_at")
    rename_index :contributions, "index_contributions_on_contribution_formula_id", "index_book_of_entries_on_subscription_plan_id" if index_name_exists?(:contributions, "index_contributions_on_contribution_formula_id")

    rename_column :attendances, :contribution_id, :book_of_entry_id
    rename_column :contributions, :contribution_formula_id, :subscription_plan_id

    rename_table :contributions, :book_of_entries
    rename_table :contribution_formulas, :subscription_plans
  end
end
