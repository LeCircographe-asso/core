# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::BugReports", type: :request do
  let(:admin) { create(:user, :admin) }

  before { login_as(admin) }

  describe "GET /admin/bug_reports" do
    it "lists reports" do
      bug_report = create(:bug_report, note: "Le calendrier ne charge pas.")

      get admin_bug_reports_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include(bug_report.note)
    end

    it "filters by status" do
      resolved = create(:bug_report, status: :resolved, note: "Le calendrier ne charge plus.")
      create(:bug_report, status: :new_report)

      get admin_bug_reports_path(status: "resolved")

      expect(response.body).to include(resolved.note)
    end

    it "blocks volunteers" do
      login_as(create(:user, :volunteer))

      get admin_bug_reports_path

      expect(response).to redirect_to(admin_dashboard_index_path)
    end

    it "shows the device/display badge and reporter role" do
      create(:bug_report, device_type: "mobile", display_mode: "standalone", reporter_role: "admin")

      get admin_bug_reports_path

      expect(response.body).to include(I18n.t("admin.bug_reports.device_types.mobile"))
      expect(response.body).to include(I18n.t("admin.bug_reports.display_modes.standalone"))
      expect(response.body).to include(I18n.t("admin.bug_reports.roles.admin"))
    end

    it "shows a collapsible JS error summary when present" do
      create(:bug_report, js_errors: [ { "type" => "error", "message" => "Cannot read properties of undefined" } ])

      get admin_bug_reports_path

      expect(response.body).to include("Cannot read properties of undefined")
    end

    it "filters by source" do
      auto = BugReport.record_automatic!(error_class: "StandardError", message: "boom", kind: :error, path: "/x")
      create(:bug_report)

      get admin_bug_reports_path(source: "automatic")

      expect(response.body).to include(auto.note)
      expect(response.body).to include(I18n.t("admin.bug_reports.sources.automatic"))
    end

    it "shows the occurrence count for a report seen multiple times" do
      BugReport.record_automatic!(error_class: "StandardError", message: "boom", kind: :error, path: "/x")
      BugReport.record_automatic!(error_class: "StandardError", message: "boom", kind: :error, path: "/x")

      get admin_bug_reports_path

      expect(response.body).to include("×2")
    end
  end

  describe "PATCH /admin/bug_reports/:id" do
    it "updates the status" do
      bug_report = create(:bug_report, status: :new_report)

      patch admin_bug_report_path(bug_report), params: { status: "resolved" }

      expect(bug_report.reload).to be_resolved
      expect(response).to redirect_to(admin_bug_reports_path)
    end

    # form_with url: (sans model:/scope:) rend des champs non-scopés — regression guard :
    # si ce select venait à être scopé (name="bug_report[status]"), le test ci-dessus
    # continuerait de passer (il poste `status` directement) sans jamais le détecter.
    it "renders the status select unscoped, matching what the controller reads" do
      create(:bug_report, status: :new_report)

      get admin_bug_reports_path

      expect(response.body).to match(/<select[^>]*name="status"/)
      expect(response.body).not_to include('name="bug_report[status]"')
    end

    it "records who handled the ticket" do
      bug_report = create(:bug_report, status: :new_report)

      patch admin_bug_report_path(bug_report), params: { status: "in_progress" }

      expect(bug_report.reload.updated_by_user).to eq(admin)
    end

    it "shows who last handled a ticket" do
      bug_report = create(:bug_report, status: :resolved, updated_by_user: admin)

      get admin_bug_reports_path

      expect(response.body).to include(I18n.t("admin.bug_reports.table.handled_by", name: admin.full_name))
    end

    it "does not show a handled-by note for an untouched ticket" do
      create(:bug_report, status: :new_report, updated_by_user: nil)

      get admin_bug_reports_path

      expect(response.body).not_to include(I18n.t("admin.bug_reports.table.handled_by", name: ""))
    end

    it "rejects an invalid status without a 500" do
      bug_report = create(:bug_report, status: :new_report)

      patch admin_bug_report_path(bug_report), params: { status: "not_a_real_status" }

      expect(response).to redirect_to(admin_bug_reports_path)
      expect(flash[:alert]).to eq(I18n.t("admin.bug_reports.update.invalid_status"))
      expect(bug_report.reload).to be_new_report
    end
  end
end
