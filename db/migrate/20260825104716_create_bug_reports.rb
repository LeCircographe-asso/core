# frozen_string_literal: true

class CreateBugReports < ActiveRecord::Migration[8.1]
  def change
    create_table :bug_reports do |t|
      t.text    :note,       null: false
      t.string  :page_url
      t.string  :user_agent
      t.integer :status,     null: false, default: 0
      t.references :person, foreign_key: true

      t.timestamps
    end

    add_index :bug_reports, :status
  end
end
