class AddExpirationDateToUserMemberships < ActiveRecord::Migration[8.0]
  def change
    add_column :user_memberships, :expiration_date, :date
  end
end
