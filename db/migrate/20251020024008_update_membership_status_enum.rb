class UpdateMembershipStatusEnum < ActiveRecord::Migration[8.0]
  def up
    # Mettre à jour les valeurs existantes pour le nouvel enum
    # inactive: 0 -> pending: 0 (pas de changement)
    # active: 1 -> inactive: 1 (changer 1 vers 1, pas de changement)
    # expired: 2 -> active: 2 (changer 2 vers 2, pas de changement)
    # expired: 2 -> expired: 3 (changer 2 vers 3)

    # Mettre à jour les adhésions expirées (status 2 -> 3)
    execute "UPDATE memberships SET status = 3 WHERE status = 2"

    # Mettre à jour les adhésions actives (status 1 -> 2)
    execute "UPDATE memberships SET status = 2 WHERE status = 1"

    # Les adhésions inactives (status 0) restent à 0 (maintenant pending)
  end

  def down
    # Revenir aux anciennes valeurs
    # pending: 0 -> inactive: 0 (pas de changement)
    # inactive: 1 -> active: 1 (changer 1 vers 1, pas de changement)
    # active: 2 -> expired: 2 (changer 2 vers 2, pas de changement)
    # expired: 3 -> expired: 2 (changer 3 vers 2)

    # Mettre à jour les adhésions expirées (status 3 -> 2)
    execute "UPDATE memberships SET status = 2 WHERE status = 3"

    # Mettre à jour les adhésions actives (status 2 -> 1)
    execute "UPDATE memberships SET status = 1 WHERE status = 2"
  end
end
