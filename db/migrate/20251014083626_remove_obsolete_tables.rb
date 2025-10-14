class RemoveObsoleteTables < ActiveRecord::Migration[8.0]
  def change
    # Tables obsolètes qui ne correspondent pas au modèle Person-Based
    # On garde : attendance_lists (fonctionnel), blogs (fonctionnel),
    # sessions (authentification Rails 8), price_catalogs (prix modifiables)

    # Système d'inscription aux événements - sera remplacé par attendances directes
    # mais on garde pour l'instant car fonctionnel
    # drop_table :event_attendees, if_exists: true

    # On ne supprime rien pour l'instant - toutes les tables sont fonctionnelles
    # Cette migration est un placeholder pour les futures suppressions
    puts "✅ Aucune table supprimée - toutes les tables actuelles sont fonctionnelles"
  end
end
