class CreatePeopleTable < ActiveRecord::Migration[8.0]
  def change
    create_table :people do |t|
      # Informations personnelles de base
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :phone
      t.string :email
      t.text :address
      t.date :birth_date

      # Contact d'urgence
      t.string :emergency_contact_name
      t.string :emergency_contact_phone

      # Informations complémentaires
      t.text :notes
      t.string :occupation
      t.string :specialty

      # Droits et préférences
      t.boolean :image_rights, default: false
      t.boolean :get_involved, default: false
      t.boolean :newsletter_subscribed, default: false
      t.boolean :dyslexic_font, default: false

      # Métadonnées
      t.timestamps
    end

    # Index pour les recherches fréquentes
    add_index :people, :email, unique: true
    add_index :people, [ :first_name, :last_name ]
    add_index :people, :phone
  end
end
