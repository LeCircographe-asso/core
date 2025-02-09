class CreateTrainingSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :training_sessions do |t|
      t.date :date, null: false
      t.string :status, default: 'open', null: false
      t.references :recorded_by, foreign_key: { to_table: :users }
      t.text :notes
      t.integer :year_reference  # Pour les statistiques annuelles
      t.integer :week_number     # Pour les statistiques hebdomadaires
      t.integer :month_number    # Pour les statistiques mensuelles

      t.timestamps

      t.index :date, unique: true
      t.index :status
      t.index :year_reference
      t.index :week_number
      t.index :month_number
      t.index [:year_reference, :week_number]
      t.index [:year_reference, :month_number]
    end
  end
end 