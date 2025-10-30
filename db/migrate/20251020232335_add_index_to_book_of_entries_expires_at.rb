class AddIndexToBookOfEntriesExpiresAt < ActiveRecord::Migration[8.0]
  def change
    # Index pour optimiser les requêtes d'expiration
    add_index :book_of_entries, :expires_at
  end
end
