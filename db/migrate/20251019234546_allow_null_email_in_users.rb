class AllowNullEmailInUsers < ActiveRecord::Migration[8.0]
  def change
    # Permettre les valeurs NULL dans email_address pour les comptes créés par admin
    change_column_null :users, :email_address, true

    # Note: SQLite ne supporte pas les index partiels avec WHERE
    # L'unicité sera gérée au niveau application dans le modèle User
    # avec la validation custom email_uniqueness_unless_person_email
  end
end
