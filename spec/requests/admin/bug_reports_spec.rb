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
  end

  describe "PATCH /admin/bug_reports/:id" do
    it "updates the status" do
      bug_report = create(:bug_report, status: :new_report)

      patch admin_bug_report_path(bug_report), params: { status: "resolved" }

      expect(bug_report.reload).to be_resolved
      expect(response).to redirect_to(admin_bug_reports_path)
    end
  end
end
