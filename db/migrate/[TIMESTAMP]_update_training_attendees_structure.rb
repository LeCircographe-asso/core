class UpdateTrainingAttendeesStructure < ActiveRecord::Migration[8.0]
  def change
    change_table :training_attendees do |t|
      # Ajout des références manquantes
      t.references :training_session, null: false, foreign_key: true
      t.references :recorded_by, foreign_key: { to_table: :users }
      
      # Renommer comments en notes pour cohérence
      t.rename :comments, :notes
      
      # Modifier la contrainte de user_membership
      change_column_null :training_attendees, :user_membership_id, true
      
      # Ajouter un index composé pour la validation d'unicité
      add_index :training_attendees, [:user_id, :training_session_id, :created_at], 
                unique: true, 
                name: 'index_training_attendees_on_user_session_date'
    end
  end
end 