class FixBookOfEntrySessionsRemaining < ActiveRecord::Migration[8.0]
  def change
    # Fix contradiction: sessions_remaining should be NULL for unlimited subscriptions
    # This allows proper validation separation between limited (pack10/day) and unlimited (trimester/annual)
    change_column_null :book_of_entries, :sessions_remaining, true
    change_column_default :book_of_entries, :sessions_remaining, nil
  end
end
