class RefactorPaymentsTable < ActiveRecord::Migration[8.0]
  def change
    # Remplacer user_id par person_id selon le domain_model_circographe.md
    # D'abord nullable pour éviter les erreurs de contrainte
    add_reference :payments, :person, null: true, foreign_key: true

    # Ajouter recorded_by_id (utilisateur qui a enregistré le paiement)
    add_reference :payments, :recorded_by, null: true, foreign_key: { to_table: :users }

    # Ajouter payment_method selon le domain_model_circographe.md
    add_column :payments, :payment_method, :integer, default: 0

    # Ajouter notes pour des informations complémentaires
    add_column :payments, :notes, :text

    # Renommer payment_amount en total_cents pour cohérence
    rename_column :payments, :payment_amount, :total_cents

    # Index pour les recherches fréquentes
    add_index :payments, [ :person_id, :payment_method ]
    add_index :payments, :payment_method

    # Enum pour les méthodes de paiement selon le domain_model_circographe.md
    # payment_method: { cash: 0, sumup: 1, cheque: 2, transfer: 3 }
  end
end
