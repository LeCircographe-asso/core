class CreateExceptionalClosures < ActiveRecord::Migration[8.1]
  def change
    create_table :exceptional_closures do |t|
      t.boolean :active, null: false, default: false
      t.date :ends_on
      t.string :label
      t.references :updated_by_user, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
