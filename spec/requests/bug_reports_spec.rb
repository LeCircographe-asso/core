# frozen_string_literal: true

require "rails_helper"

RSpec.describe "BugReports", type: :request do
  describe "POST /bug_reports" do
    it "does not require authentication" do
      expect do
        post bug_reports_path, params: { note: "Le bouton ne répond pas." }, as: :turbo_stream
      end.to change(BugReport, :count).by(1)

      expect(response).to have_http_status(:success)
      expect(response.body).to include(I18n.t("bug_reports.create.success_title"))
    end

    it "links the report to the logged-in person" do
      user = create(:user)

      login_as(user)

      post bug_reports_path, params: { note: "Erreur 500." }, as: :turbo_stream

      expect(BugReport.last.person).to eq(user.person)
    end

    it "re-renders the form with an error when the note is blank" do
      post bug_reports_path, params: { note: "" }, as: :turbo_stream

      expect(response).to have_http_status(:success)
      expect(response.body).to include(I18n.t("bug_reports.form.note_label"))
    end

    it "snapshots the logged-in user's role server-side" do
      login_as(create(:user, :admin))

      post bug_reports_path, params: { note: "Bug." }, as: :turbo_stream

      expect(BugReport.last.reporter_role).to eq("admin")
    end

    it "ignores a client-supplied reporter_role instead of trusting it" do
      post bug_reports_path, params: { note: "Bug.", reporter_role: "super_admin" }, as: :turbo_stream

      expect(BugReport.last.reporter_role).to be_nil
    end

    it "stores the device context sent by the widget's JS" do
      post bug_reports_path, params: {
        note: "Bug.",
        device_type: "mobile",
        display_mode: "standalone",
        viewport_width: "390",
        viewport_height: "844",
        js_errors: [ { type: "error", message: "boom" } ].to_json
      }, as: :turbo_stream

      bug_report = BugReport.last
      expect(bug_report.device_type).to eq("mobile")
      expect(bug_report.display_mode).to eq("standalone")
      expect(bug_report.viewport_width).to eq(390)
      expect(bug_report.js_errors).to eq([ { "type" => "error", "message" => "boom" } ])
    end
  end
end
