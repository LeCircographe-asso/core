# frozen_string_literal: true

class CreateBugReportWidgetSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :bug_report_widget_settings do |t|
      t.boolean :enabled, null: false, default: false
      t.references :updated_by_user, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
