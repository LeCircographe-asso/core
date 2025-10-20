class AllowNullEmailInPeople < ActiveRecord::Migration[8.0]
  def change
    # Permettre les valeurs NULL pour l'email dans la table people
    change_column_null :people, :email, true
    
    # Supprimer l'index unique sur email s'il existe
    remove_index :people, :email if index_exists?(:people, :email)
    
    # Recréer l'index unique mais seulement pour les emails non-null
    add_index :people, :email, unique: true, where: "email IS NOT NULL AND email != ''"
  end
end
