# frozen_string_literal: true

require "rails_helper"

RSpec.describe Support::BugReportSubmitter do
  describe "#call" do
    it "creates a bug report with the given note" do
      result = described_class.new(note: "Le calendrier ne charge pas.", page_url: "https://example.com/x", user_agent: "RSpec").call

      expect(result).to be_success
      expect(result.bug_report).to be_persisted
      expect(result.bug_report.note).to eq("Le calendrier ne charge pas.")
      expect(result.bug_report.status).to eq("new_report")
    end

    it "links the report to a person when person_id is given" do
      person = create(:person)

      result = described_class.new(note: "Bug.", person_id: person.id).call

      expect(result.bug_report.person).to eq(person)
    end

    it "fails without a note" do
      result = described_class.new(note: "").call

      expect(result).not_to be_success
      expect(BugReport.count).to eq(0)
    end

    it "stores device/display context and reporter_role" do
      result = described_class.new(
        note: "Bug.",
        device_type: "mobile",
        display_mode: "standalone",
        viewport_width: 390,
        viewport_height: 844,
        reporter_role: "admin"
      ).call

      bug_report = result.bug_report
      expect(bug_report.device_type).to eq("mobile")
      expect(bug_report.display_mode).to eq("standalone")
      expect(bug_report.viewport_width).to eq(390)
      expect(bug_report.reporter_role).to eq("admin")
    end

    it "parses and stores js_errors from the client-provided JSON" do
      payload = [ { "type" => "error", "message" => "Cannot read properties of undefined", "line" => 42 } ].to_json

      result = described_class.new(note: "Bug.", js_errors_json: payload).call

      expect(result.bug_report.js_errors).to eq([
        { "type" => "error", "message" => "Cannot read properties of undefined", "line" => 42 }
      ])
    end

    it "ignores malformed js_errors JSON instead of failing the submission" do
      result = described_class.new(note: "Bug.", js_errors_json: "not json").call

      expect(result).to be_success
      expect(result.bug_report.js_errors).to eq([])
    end

    it "caps the number of stored js_errors" do
      payload = Array.new(30) { |i| { "type" => "error", "message" => "err #{i}" } }.to_json

      result = described_class.new(note: "Bug.", js_errors_json: payload).call

      expect(result.bug_report.js_errors.size).to eq(Support::BugReportSubmitter::MAX_JS_ERRORS)
    end

    it "drops unknown keys from each js_errors entry" do
      payload = [ { "type" => "error", "message" => "boom", "evil_key" => "<script>" } ].to_json

      result = described_class.new(note: "Bug.", js_errors_json: payload).call

      expect(result.bug_report.js_errors.first.keys).to contain_exactly("type", "message")
    end
  end
end
