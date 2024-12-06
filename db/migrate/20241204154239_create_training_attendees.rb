class CreateTrainingAttendees < ActiveRecord::Migration[8.0]
  def change
    create_table :training_attendees do |t|
      t.references :user, null: false, foreign_key: true
      t.references :user_membership, null: false, foreign_key: true
      t.boolean :check
      t.text :comments

      t.timestamps
    end
  end
end
