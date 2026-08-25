# frozen_string_literal: true

module Admin
  class BugReportsController < BaseController
    before_action :require_admin_rights
    before_action :set_bug_report, only: :update

    def index
      @bug_reports = BugReport.includes(:person).ordered

      @bug_reports = @bug_reports.where(status: params[:status]) if params[:status].present?

      @pagy, @bug_reports = pagy(@bug_reports, items: 20)

      @widget_setting = BugReportWidgetSetting.current

      add_breadcrumb I18n.t("breadcrumbs.admin.common.dashboard"), admin_dashboard_index_path
      add_breadcrumb I18n.t("admin.bug_reports.breadcrumb"), nil
    end

    def update
      @bug_report.update!(status: params[:status])
      redirect_to admin_bug_reports_path(status: params[:filter_status]), notice: t(".success")
    end

    private

    def set_bug_report
      @bug_report = BugReport.find(params[:id])
    end
  end
end
