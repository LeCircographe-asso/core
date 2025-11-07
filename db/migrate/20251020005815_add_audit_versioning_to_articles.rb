class AddAuditVersioningToArticles < ActiveRecord::Migration[8.0]
  def change
    # Versioning léger pour les types d'adhésion
    add_column :membership_types, :version, :integer, default: 1, null: false
    add_column :membership_types, :effective_from, :date, null: true
    add_column :membership_types, :effective_until, :date, null: true
    add_column :membership_types, :created_by_user_id, :integer, null: true
    add_column :membership_types, :change_reason, :text, null: true

    # Versioning léger pour les plans d'abonnement
    add_column :subscription_plans, :version, :integer, default: 1, null: false
    add_column :subscription_plans, :effective_from, :date, null: true
    add_column :subscription_plans, :effective_until, :date, null: true
    add_column :subscription_plans, :created_by_user_id, :integer, null: true
    add_column :subscription_plans, :change_reason, :text, null: true

    # Index pour les performances d'audit
    add_index :membership_types, [ :effective_from, :effective_until ], name: 'idx_membership_types_effective_period'
    add_index :subscription_plans, [ :effective_from, :effective_until ], name: 'idx_subscription_plans_effective_period'
    add_index :membership_types, :created_by_user_id
    add_index :subscription_plans, :created_by_user_id

    # Clés étrangères pour l'audit
    add_foreign_key :membership_types, :users, column: :created_by_user_id
    add_foreign_key :subscription_plans, :users, column: :created_by_user_id
  end
end
