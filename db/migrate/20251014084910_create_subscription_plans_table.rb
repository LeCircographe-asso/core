class CreateSubscriptionPlansTable < ActiveRecord::Migration[8.0]
  def change
    create_table :subscription_plans do |t|
      # Informations de base
      t.string :name, null: false
      t.integer :duration, null: false
      t.integer :price_cents, null: false
      t.text :description
      
      # Colonnes spécifiques aux packs
      t.integer :sessions_count # Pour pack10 (nombre de séances)
      t.integer :validity_days # Durée de validité en jours
      
      # Relation avec membership_type
      t.references :membership_type, null: false, foreign_key: true
      
      # Métadonnées
      t.timestamps
    end
    
    # Index pour les recherches
    add_index :subscription_plans, :duration
    add_index :subscription_plans, :name, unique: true
    # membership_type_id index créé automatiquement par add_reference
    
    # Enum pour les durées selon le domain_model_circographe.md
    # duration: { day: 0, trimester: 1, annual: 2, pack10: 3 }
  end
end
