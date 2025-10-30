class MigrateNewsletterTokenToPerson < ActiveRecord::Migration[8.1]
  def up
    # Ajouter token à Person
    add_column :people, :newsletter_unsubscribe_token, :string
    add_index :people, :newsletter_unsubscribe_token, unique: true
    
    # Migrer tokens existants User → Person
    User.where.not(unsubscribe_token: nil).find_each do |user|
      if user.person.present?
        user.person.update_column(:newsletter_unsubscribe_token, user.unsubscribe_token)
      end
    end
    
    # Supprimer ancienne colonne
    remove_column :users, :unsubscribe_token
  end
  
  def down
    add_column :users, :unsubscribe_token, :string
    
    Person.where.not(newsletter_unsubscribe_token: nil).find_each do |person|
      if person.user.present?
        person.user.update_column(:unsubscribe_token, person.newsletter_unsubscribe_token)
      end
    end
    
    remove_column :people, :newsletter_unsubscribe_token
  end
end
