class RemoveNewsletterFromUsers < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :newsletter, :boolean
  end
end
