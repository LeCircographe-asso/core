class AdaptAttendancesToPersonModel < ActiveRecord::Migration[8.0]
  def change
    # Ajouter person_id selon le domain_model_circographe.md
    add_reference :attendances, :person, null: true, foreign_key: true
    
    # Ajouter event_id (optionnel) selon le domain_model_circographe.md
    add_reference :attendances, :event, null: true, foreign_key: true
    
    # Ajouter une colonne date pour simplifier
    add_column :attendances, :date, :date
    
    # Index pour les recherches fréquentes
    add_index :attendances, [:person_id, :date], unique: true
    add_index :attendances, :date
    
    # La colonne user_id existe déjà, on la garde pour compatibilité
    # La colonne attendance_list_id existe déjà, on la garde pour compatibilité
  end
end
