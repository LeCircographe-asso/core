# frozen_string_literal: true

class AddAutomaticReportingToBugReports < ActiveRecord::Migration[8.1]
  def change
    add_column :bug_reports, :source, :integer, null: false, default: 0
    add_column :bug_reports, :fingerprint, :string
    add_column :bug_reports, :occurrence_count, :integer, null: false, default: 1

    add_index :bug_reports, :fingerprint
  end
end
