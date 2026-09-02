# frozen_string_literal: true

class AddDeviceContextToBugReports < ActiveRecord::Migration[8.1]
  def change
    add_column :bug_reports, :device_type, :string
    add_column :bug_reports, :display_mode, :string
    add_column :bug_reports, :viewport_width, :integer
    add_column :bug_reports, :viewport_height, :integer
    add_column :bug_reports, :reporter_role, :string
    add_column :bug_reports, :js_errors, :json, default: []
  end
end
