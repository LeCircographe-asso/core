# frozen_string_literal: true

class AddUpdatedByUserToBugReports < ActiveRecord::Migration[8.1]
  def change
    # Qui a traité le ticket (marqué en cours/résolu/etc.) — même patron que
    # BugReportWidgetSetting#updated_by_user. Utile pour le suivi de charge admin,
    # pas seulement l'audit : savoir qui a déjà regardé quoi.
    add_reference :bug_reports, :updated_by_user, foreign_key: { to_table: :users }, null: true

    # Timestamp dédié à "la dernière fois que cette erreur s'est vraiment produite",
    # distinct de `updated_at` : celui-ci bouge aussi quand un admin change juste le
    # statut, ce qui rendrait le ticket "récent" pour la fenêtre de dédoublonnage
    # (BugReport.record_automatic!) sans rapport avec une occurrence réelle — un
    # admin qui traite un vieux ticket il y a longtemps résolu le rendrait de
    # nouveau éligible au regroupement pour une erreur différente sur la même route.
    add_column :bug_reports, :last_occurred_at, :datetime
    reversible do |dir|
      dir.up { execute "UPDATE bug_reports SET last_occurred_at = updated_at" }
    end

    remove_index :bug_reports, :fingerprint
    add_index :bug_reports, [ :fingerprint, :last_occurred_at ]
  end
end
