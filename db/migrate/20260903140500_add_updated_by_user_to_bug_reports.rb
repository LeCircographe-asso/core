# frozen_string_literal: true

class AddUpdatedByUserToBugReports < ActiveRecord::Migration[8.1]
  def change
    # Qui a traité le ticket (marqué en cours/résolu/etc.) — même patron que
    # BugReportWidgetSetting#updated_by_user. Utile pour le suivi de charge admin,
    # pas seulement l'audit : savoir qui a déjà regardé quoi.
    add_reference :bug_reports, :updated_by_user, foreign_key: { to_table: :users }, null: true

    # Remplace l'index simple sur fingerprint : la seule requête qui le lit
    # (BugReport.record_automatic!) filtre toujours par fingerprint ET updated_at
    # ensemble, ce composite couvre ce cas exactement (et le seul fingerprint: en préfixe).
    remove_index :bug_reports, :fingerprint
    add_index :bug_reports, [ :fingerprint, :updated_at ]
  end
end
