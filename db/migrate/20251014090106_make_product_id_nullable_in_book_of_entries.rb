class MakeProductIdNullableInBookOfEntries < ActiveRecord::Migration[8.0]
  def change
    # Rendre product_id et user_id nullable pour la compatibilité avec l'ancien système
    change_column_null :book_of_entries, :product_id, true
    change_column_null :book_of_entries, :user_id, true
  end
end
