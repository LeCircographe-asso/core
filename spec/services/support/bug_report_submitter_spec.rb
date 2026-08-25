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
  end
end
