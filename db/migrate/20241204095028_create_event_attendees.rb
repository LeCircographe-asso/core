class CreateEventAttendees < ActiveRecord::Migration[8.0]
  def change
    create_table :event_attendees do |t|
      t.references :user, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.references :payment, foreign_key: true
      t.boolean :interested, default: false

      t.timestamps
    end
  end
end
