class AddPersonIdToUsers < ActiveRecord::Migration[8.0]
  def change
    add_reference :users, :person, null: true, foreign_key: true
    # Index créé automatiquement par add_reference
  end
end
