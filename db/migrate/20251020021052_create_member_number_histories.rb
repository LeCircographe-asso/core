class CreateMemberNumberHistories < ActiveRecord::Migration[8.0]
  def change
    create_table :member_number_histories do |t|
      t.references :person, null: false, foreign_key: true
      t.string :member_number, null: false
      t.string :membership_type, null: false
      t.integer :year, null: false
      t.text :notes # Pour expliquer le changement (ex: "Changement de Basique vers Cirque")
      t.datetime :assigned_at, null: false # Quand le numéro a été assigné
      t.datetime :replaced_at # Quand le numéro a été remplacé

      t.timestamps
    end

    add_index :member_number_histories, :member_number, unique: true
    add_index :member_number_histories, [ :person_id, :assigned_at ]
  end
end
