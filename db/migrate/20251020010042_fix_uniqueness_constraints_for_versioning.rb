class FixUniquenessConstraintsForVersioning < ActiveRecord::Migration[8.0]
  def change
    # Supprimer les contraintes d'unicité existantes
    remove_index :membership_types, :name if index_exists?(:membership_types, :name)
    remove_index :subscription_plans, :name if index_exists?(:subscription_plans, :name)
    
    # Ajouter des contraintes d'unicité composées pour le versioning
    add_index :membership_types, [:name, :version], unique: true, name: 'idx_membership_types_name_version'
    add_index :subscription_plans, [:name, :version], unique: true, name: 'idx_subscription_plans_name_version'
  end
end
