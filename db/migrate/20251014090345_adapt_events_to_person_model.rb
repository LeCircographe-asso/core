class AdaptEventsToPersonModel < ActiveRecord::Migration[8.0]
  def change
    # Renommer title en name selon le domain_model_circographe.md
    rename_column :events, :title, :name

    # Ajouter category selon le domain_model_circographe.md
    add_column :events, :category, :integer, default: 0

    # Remplacer les 3 descriptions par une seule
    add_column :events, :description, :text

    # Index pour les recherches
    add_index :events, :category
    add_index :events, :date

    # La colonne creator_id existe déjà, on la garde
    # Les colonnes upper_description, middle_description, bottom_description existent, on les garde pour compatibilité

    # Enum pour les catégories selon le domain_model_circographe.md
    # category: { show: 0, workshop: 1, volunteering: 2, other: 3 }
  end
end
