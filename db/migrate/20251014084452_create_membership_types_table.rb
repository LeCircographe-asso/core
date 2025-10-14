class CreateMembershipTypesTable < ActiveRecord::Migration[8.0]
  def change
    create_table :membership_types do |t|
      # Informations de base
      t.string :name, null: false
      t.integer :category, null: false
      t.integer :price_cents, null: false
      t.text :description

      # Métadonnées
      t.timestamps
    end

    # Index pour les recherches
    add_index :membership_types, :category
    add_index :membership_types, :name, unique: true

    # Enum pour les catégories selon le domain_model_circographe.md
    # category: { basic: 0, circus_full: 1, circus_reduced: 2 }
  end
end
