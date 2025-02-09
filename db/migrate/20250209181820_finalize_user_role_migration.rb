class FinalizeUserRoleMigration < ActiveRecord::Migration[8.0]
  def up
    # Vérification que tous les utilisateurs ont un role_new
    unless User.where(role_new: nil).exists?
      remove_column :users, :role
      rename_column :users, :role_new, :role
    else
      raise "Certains utilisateurs n'ont pas de nouveau rôle attribué"
    end
  end

  def down
    rename_column :users, :role, :role_new
    add_column :users, :role, :string
    
    # Restauration des anciens rôles
    User.find_each do |user|
      old_role = case user.role_new
                 when 0
                   'guest'
                 when 1
                   'membership'
                 when 2
                   'volunteer'
                 when 3
                   'admin'
                 when 4
                   'godmode'
                 end
      user.update_column(:role, old_role)
    end
  end
end
