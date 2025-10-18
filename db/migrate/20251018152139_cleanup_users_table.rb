class CleanupUsersTable < ActiveRecord::Migration[8.0]
  def up
    # 1. Ajouter les champs manquants à la table people
    add_column :people, :zip_code, :string
    add_column :people, :town, :string
    add_column :people, :country, :string

    # 2. Migrer les données des users vers people (si des users existent)
    User.includes(:person).find_each do |user|
      next unless user.person
      
      # Migrer les champs vers la personne liée
      user.person.update_columns(
        zip_code: user.zip_code,
        town: user.town,
        country: user.country
      )
    end

    # 3. Supprimer les colonnes dupliquées de la table users
    remove_column :users, :last_name, :string
    remove_column :users, :first_name, :string
    remove_column :users, :birthdate, :date
    remove_column :users, :address, :text
    remove_column :users, :zip_code, :string
    remove_column :users, :town, :text
    remove_column :users, :country, :string
    remove_column :users, :phone_number, :string
    remove_column :users, :occupation, :text
    remove_column :users, :specialty, :text
    remove_column :users, :image_rights, :boolean
    remove_column :users, :get_involved, :boolean
    remove_column :users, :newsletter_subscribed, :boolean
    remove_column :users, :dyslexic_font, :boolean
    remove_column :users, :full_name, :string
  end

  def down
    # Restaurer les colonnes supprimées
    add_column :users, :last_name, :string
    add_column :users, :first_name, :string
    add_column :users, :birthdate, :date
    add_column :users, :address, :text
    add_column :users, :zip_code, :string
    add_column :users, :town, :text
    add_column :users, :country, :string
    add_column :users, :phone_number, :string
    add_column :users, :occupation, :text
    add_column :users, :specialty, :text
    add_column :users, :image_rights, :boolean, default: false
    add_column :users, :get_involved, :boolean, default: false
    add_column :users, :newsletter_subscribed, :boolean
    add_column :users, :dyslexic_font, :boolean, default: false
    add_column :users, :full_name, :string

    # Migrer les données de people vers users
    User.includes(:person).find_each do |user|
      next unless user.person
      
      user.update_columns(
        last_name: user.person.last_name,
        first_name: user.person.first_name,
        birthdate: user.person.birth_date,
        address: user.person.address,
        zip_code: user.person.zip_code,
        town: user.person.town,
        country: user.person.country,
        phone_number: user.person.phone,
        occupation: user.person.occupation,
        specialty: user.person.specialty,
        image_rights: user.person.image_rights,
        get_involved: user.person.get_involved,
        newsletter_subscribed: user.person.newsletter_subscribed,
        dyslexic_font: user.person.dyslexic_font,
        full_name: user.person.full_name
      )
    end

    # Supprimer les colonnes ajoutées à people
    remove_column :people, :zip_code, :string
    remove_column :people, :town, :string
    remove_column :people, :country, :string
  end
end
