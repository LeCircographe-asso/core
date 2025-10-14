class CreatePaymentLinesTable < ActiveRecord::Migration[8.0]
  def change
    create_table :payment_lines do |t|
      # Relation avec le paiement
      t.references :payment, null: false, foreign_key: true

      # Relation polymorphique vers l'item acheté (membership, subscription_plan, etc.)
      t.string :item_type, null: false
      t.bigint :item_id, null: false

      # Informations sur la ligne
      t.integer :amount_cents, null: false
      t.string :description

      # Métadonnées
      t.timestamps
    end

    # Index pour les recherches
    add_index :payment_lines, [ :item_type, :item_id ]
    # payment_id index créé automatiquement par add_reference

    # Index composite pour éviter les doublons
    add_index :payment_lines, [ :payment_id, :item_type, :item_id ], unique: true, name: 'index_payment_lines_unique_item'
  end
end
