class UpdateTrainingAttendeesStructure < ActiveRecord::Migration[8.0]
  def up
    # D'abord créer la table training_sessions
    create_table :training_sessions do |t|
      t.date :date, null: false
      t.string :status, default: 'open'
      t.integer :max_capacity, default: 20
      t.references :recorded_by, foreign_key: { to_table: :users }
      t.text :notes

      t.timestamps
    end

    add_index :training_sessions, [:date], unique: true

    # Ensuite ajouter les colonnes à training_attendees
    add_reference :training_attendees, :training_session, foreign_key: true
    add_reference :training_attendees, :recorded_by, foreign_key: { to_table: :users }
    
    # Renommer la colonne
    rename_column :training_attendees, :comments, :notes
    
    # Modifier la contrainte
    change_column_null :training_attendees, :user_membership_id, true
    
    # Ajouter l'index
    add_index :training_attendees, 
              [:user_id, :training_session_id, :created_at], 
              unique: true, 
              name: 'index_training_attendees_on_user_session_date'
  end

  def down
    remove_reference :training_attendees, :training_session
    remove_reference :training_attendees, :recorded_by
    
    rename_column :training_attendees, :notes, :comments
    change_column_null :training_attendees, :user_membership_id, false
    
    remove_index :training_attendees, name: 'index_training_attendees_on_user_session_date'
    
    drop_table :training_sessions
  end
end
