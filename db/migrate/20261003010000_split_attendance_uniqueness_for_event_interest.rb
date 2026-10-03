# frozen_string_literal: true

# L'intérêt pour un événement n'est qu'un compteur de "like" ouvert à tout
# compte web — il n'a rien à voir avec la présence quotidienne (entraînement,
# cotisation). L'index unique précédent sur (person_id, date) les confondait :
# une personne ne pouvait avoir qu'UNE présence par jour, événement ou pas,
# ce qui provoquait un crash (ActiveRecord::RecordNotUnique) dès qu'elle
# s'intéressait à un 2e événement le même jour, ou qu'elle s'intéressait à un
# événement le jour où elle s'était déjà entraînée.
#
# On sépare les deux contraintes :
# - une personne n'a qu'une présence d'entraînement par jour (event_id NULL)
# - une personne ne peut "aimer" un même événement qu'une fois (event_id présent)
class SplitAttendanceUniquenessForEventInterest < ActiveRecord::Migration[8.1]
  def change
    remove_index :attendances, name: "index_attendances_on_person_id_and_date"

    add_index :attendances, [ :person_id, :date ], unique: true,
      where: "event_id IS NULL",
      name: "index_attendances_on_person_id_and_date_without_event"

    add_index :attendances, [ :person_id, :event_id ], unique: true,
      where: "event_id IS NOT NULL",
      name: "index_attendances_on_person_id_and_event_id"
  end
end
