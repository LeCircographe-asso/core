class AllowNullExpiresAtInBookOfEntries < ActiveRecord::Migration[8.0]
  def change
    # Rendre expires_at nullable pour permettre les packs10 sans expiration
    change_column_null :book_of_entries, :expires_at, true
  end
end
