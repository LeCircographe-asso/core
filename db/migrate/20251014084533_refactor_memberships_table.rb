class RefactorMembershipsTable < ActiveRecord::Migration[8.0]
  def change
    # Supprimer l'ancienne colonne type_name (remplacée par membership_type_id)
    remove_column :memberships, :type_name, :integer

    # Ajouter les nouvelles colonnes selon le domain_model_circographe.md
    # D'abord nullable, puis on remplira les données
    add_reference :memberships, :person, null: true, foreign_key: true
    add_reference :memberships, :membership_type, null: true, foreign_key: true

    # Ajouter les colonnes de dates et statut (nullable pour l'instant)
    add_column :memberships, :started_at, :date
    add_column :memberships, :ended_at, :date
    add_column :memberships, :status, :integer, default: 1
    add_column :memberships, :first_joined_at, :date

    # Index pour les recherches fréquentes
    add_index :memberships, [ :person_id, :status ]
    add_index :memberships, :status
    add_index :memberships, [ :started_at, :ended_at ]

    # Enum pour les statuts selon le domain_model_circographe.md
    # status: { inactive: 0, active: 1, expired: 2 }
  end
end
