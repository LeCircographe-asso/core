class ConvertUserRoles < ActiveRecord::Migration[8.0]
  class MigrationUser < ActiveRecord::Base
    self.table_name = :users
  end

  def up
    # Conversion des rôles selon la correspondance définie
    MigrationUser.find_each do |user|
      new_role = case user.role
                 when 'guest'
                   0  # guest
                 when 'membership', 'circus_membership'
                   1  # member
                 when 'volunteer'
                   2  # volunteer
                 when 'admin'
                   3  # admin
                 when 'godmode'
                   4  # godmode
                 else
                   0  # default to guest
                 end
      
      # Sauvegarde sans validation
      user.update_column(:role_new, new_role)
    end
  end

  def down
    # Conversion inverse si nécessaire
    MigrationUser.find_each do |user|
      old_role = case user.role_new
                 when 0
                   'guest'
                 when 1
                   'membership'  # On revient à membership par défaut
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
