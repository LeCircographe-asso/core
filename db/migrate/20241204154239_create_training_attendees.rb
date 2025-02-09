class CreateTrainingAttendees < ActiveRecord::Migration[8.0]
  def change
    create_table :training_attendees do |t|
      t.references :user, null: false, foreign_key: true
      t.references :training_session, null: false, foreign_key: true
      t.references :user_membership, null: false, foreign_key: true
      t.references :checked_by, null: false, foreign_key: { to_table: :users }
      t.datetime :check_in_time, null: false
      t.boolean :is_visitor, default: false, null: false
      t.text :comments
      t.string :attendance_type, default: 'regular', null: false  # regular, makeup, special_event
      t.integer :year_reference  # Pour faciliter les stats par année scolaire
      t.integer :week_number     # Pour les stats hebdomadaires
      t.integer :month_number    # Pour les stats mensuelles

      t.timestamps

      t.index :check_in_time
      t.index [:user_id, :check_in_time], unique: true, name: 'index_training_attendees_on_user_and_time'
      t.index :attendance_type
      t.index :year_reference
      t.index :week_number
      t.index :month_number
      t.index [:year_reference, :week_number]
      t.index [:year_reference, :month_number]
    end
  end
end
