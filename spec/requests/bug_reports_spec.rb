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
  end
end
