class RefactorBookOfEntriesTable < ActiveRecord::Migration[8.0]
  def change
    # Remplacer user_id par person_id selon le domain_model_circographe.md
    add_reference :book_of_entries, :person, null: true, foreign_key: true
    
    # Remplacer product_id par subscription_plan_id
    add_reference :book_of_entries, :subscription_plan, null: true, foreign_key: true
    
    # Ajouter les colonnes manquantes selon le domain_model_circographe.md
    add_column :book_of_entries, :sessions_remaining, :integer, default: 0
    add_column :book_of_entries, :purchased_at, :datetime
    add_column :book_of_entries, :expires_at, :datetime
    
    # La colonne status existe déjà, on garde l'existante
    
    # Index pour les recherches fréquentes
    add_index :book_of_entries, [:person_id, :status]
    add_index :book_of_entries, :status
    add_index :book_of_entries, [:purchased_at, :expires_at]
    
    # Enum pour les statuts selon le domain_model_circographe.md
    # status: { inactive: 0, active: 1, expired: 2, consumed: 3 }
  end
end
