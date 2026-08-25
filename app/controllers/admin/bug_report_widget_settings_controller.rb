# frozen_string_literal: true

module Admin
  class BugReportWidgetSettingsController < BaseController
    before_action :require_super_admin

    def update
      setting = BugReportWidgetSetting.current
      setting.update!(enabled: params[:enabled] == "1", updated_by_user: current_user)

      redirect_to admin_bug_reports_path, notice: t(".success")
    end
  end
end
