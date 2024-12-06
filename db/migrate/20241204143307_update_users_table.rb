class UpdateUsersTable < ActiveRecord::Migration[8.0]
  def change
    change_table :users, bulk: true do |t|
      t.string :last_name
      t.string :first_name
      t.date :birthdate
      t.string :zip_code
      t.string :town
      t.string :country
      t.string :phone_number
      t.string :occupation
      t.string :specialty
      t.boolean :image_rights, default: false
      t.boolean :newsletter, default: false
      t.boolean :get_involved, default: false
    end
  end
end
