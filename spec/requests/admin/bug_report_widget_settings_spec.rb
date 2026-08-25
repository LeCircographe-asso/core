# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::BugReportWidgetSettings", type: :request do
  describe "PATCH /admin/bug_report_widget_setting" do
    it "lets a super admin toggle the widget on" do
      login_as(create(:user, :super_admin))

      patch admin_bug_report_widget_setting_path, params: { enabled: "1" }

      expect(BugReportWidgetSetting.current).to be_enabled
      expect(response).to redirect_to(admin_bug_reports_path)
    end

    it "blocks a regular admin" do
      login_as(create(:user, :admin))

      patch admin_bug_report_widget_setting_path, params: { enabled: "1" }

      expect(response).to redirect_to(admin_dashboard_index_path)
      expect(BugReportWidgetSetting.current).not_to be_enabled
    end
  end
end
