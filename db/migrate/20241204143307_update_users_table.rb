class UpdateUsersTable < ActiveRecord::Migration[8.0]
  def change
    change_table :users, bulk: true do |t|
      t.string :last_name
      t.string :first_name
      t.date :birthdate
      t.text :address
      t.string :zip_code
      t.text :town
      t.string :country
      t.string :phone_number
      t.text :occupation
      t.text :specialty
      t.boolean :image_rights, default: false
      t.boolean :newsletter, default: false
      t.boolean :get_involved, default: false
    end
  end
end
