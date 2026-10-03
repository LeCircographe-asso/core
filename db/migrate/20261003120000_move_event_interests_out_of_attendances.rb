# frozen_string_literal: true

# L'intérêt pour un événement (le bouton « Je suis intéressé ») n'est qu'un
# like par personne : il vivait jusqu'ici dans `attendances`, la table des
# présences, avec une date sans signification. Le partage de table forçait à
# filtrer `event_id` partout et faisait collisionner like et présence
# d'entraînement sur l'index unique (person_id, date).
#
# On le sort dans sa propre table `event_interests` (unicité person × event),
# et `attendances` redevient une table de présences, unique par jour.
#
# Remplace la migration SplitAttendanceUniquenessForEventInterest (PR #552),
# jamais déployée hors dev : selon la base, on part donc soit de l'index
# historique (person_id, date), soit des deux index partiels de #552.
class MoveEventInterestsOutOfAttendances < ActiveRecord::Migration[8.1]
  # Un like = une ligne avec event_id, sans liste de présence ni cotisation
  # consommée (aucun écran ne crée d'autre présence liée à un événement).
  INTEREST_ROWS = <<~SQL.squish
    event_id IS NOT NULL AND attendance_list_id IS NULL AND contribution_id IS NULL
  SQL

  LEGACY_INDEXES = %w[
    index_attendances_on_person_id_and_date
    index_attendances_on_person_id_and_date_without_event
    index_attendances_on_person_id_and_event_id
  ].freeze

  def up
    create_table :event_interests do |t|
      t.references :person, null: false, foreign_key: true, index: false
      t.references :event, null: false, foreign_key: true
      t.timestamps
    end
    add_index :event_interests, %i[person_id event_id], unique: true

    # GROUP BY dédoublonne les likes en double (fusions de comptes via
    # update_all, qui contournaient les validations).
    execute <<~SQL.squish
      INSERT INTO event_interests (person_id, event_id, created_at, updated_at)
      SELECT a.person_id, a.event_id, MIN(a.created_at), MAX(a.updated_at)
      FROM attendances a
      INNER JOIN people p ON p.id = a.person_id
      INNER JOIN events e ON e.id = a.event_id
      WHERE a.event_id IS NOT NULL AND a.attendance_list_id IS NULL AND a.contribution_id IS NULL
      GROUP BY a.person_id, a.event_id
    SQL
    execute "DELETE FROM attendances WHERE #{INTEREST_ROWS}"

    remove_legacy_indexes
    add_index :attendances, %i[person_id date], unique: true,
      where: "event_id IS NULL",
      name: "index_attendances_on_person_id_and_date_without_event"
  end

  # Ramène les likes dans `attendances` avec les index partiels de #552 :
  # l'index historique (person_id, date) ne peut pas être restauré sans
  # recréer le crash « deux likes le même jour ».
  def down
    execute <<~SQL.squish
      INSERT INTO attendances (person_id, event_id, date, created_at, updated_at)
      SELECT person_id, event_id, DATE(created_at), created_at, updated_at
      FROM event_interests
    SQL

    drop_table :event_interests

    remove_legacy_indexes
    add_index :attendances, %i[person_id date], unique: true,
      where: "event_id IS NULL",
      name: "index_attendances_on_person_id_and_date_without_event"
    add_index :attendances, %i[person_id event_id], unique: true,
      where: "event_id IS NOT NULL",
      name: "index_attendances_on_person_id_and_event_id"
  end

  private

  def remove_legacy_indexes
    LEGACY_INDEXES.each do |name|
      remove_index :attendances, name: name if index_name_exists?(:attendances, name)
    end
  end
end
