# frozen_string_literal: true

require "rails_helper"

RSpec.describe BugReport, type: :model do
  let(:image_path) { Rails.root.join("app/assets/images/lelieu1.webp") }

  it "is invalid without a note" do
    bug_report = BugReport.new
    expect(bug_report).not_to be_valid
    expect(bug_report.errors[:note]).to be_present
  end

  it "is valid with a note only, person and screenshot optional" do
    bug_report = BugReport.new(note: "Erreur 500 sur la fiche membre.")
    expect(bug_report).to be_valid
  end

  it "defaults to status new_report" do
    bug_report = create(:bug_report)
    expect(bug_report).to be_new_report
  end

  it "can be linked to a person or left anonymous" do
    with_person = create(:bug_report, :with_person)
    anonymous = create(:bug_report, person: nil)

    expect(with_person.person).to be_present
    expect(anonymous.person).to be_nil
  end

  it "rejects a non-image screenshot content type" do
    bug_report = BugReport.new(note: "Erreur 500 sur la fiche membre.")
    bug_report.screenshot.attach(io: File.open(image_path), filename: "notes.txt", content_type: "text/plain", identify: false)

    expect(bug_report).not_to be_valid
    expect(bug_report.errors[:screenshot]).to be_present
  end

  it "orders by most recent first" do
    older = create(:bug_report, created_at: 2.days.ago)
    newer = create(:bug_report, created_at: 1.day.ago)

    expect(BugReport.ordered).to eq([ newer, older ])
  end

  describe "device/display context" do
    it "accepts a known device_type and display_mode" do
      bug_report = build(:bug_report, device_type: "mobile", display_mode: "standalone")
      expect(bug_report).to be_valid
    end

    it "leaves device_type and display_mode nil when not provided" do
      bug_report = build(:bug_report)
      expect(bug_report.device_type).to be_nil
      expect(bug_report.display_mode).to be_nil
    end

    it "rejects an unknown device_type instead of raising" do
      bug_report = build(:bug_report, device_type: "smart_fridge")
      expect(bug_report).not_to be_valid
      expect(bug_report.errors[:device_type]).to be_present
    end

    it "rejects an unknown reporter_role" do
      bug_report = build(:bug_report, reporter_role: "dictator")
      expect(bug_report).not_to be_valid
      expect(bug_report.errors[:reporter_role]).to be_present
    end

    it "stores js_errors as an array of hashes" do
      bug_report = create(:bug_report, js_errors: [ { "type" => "error", "message" => "boom" } ])
      expect(bug_report.reload.js_errors).to eq([ { "type" => "error", "message" => "boom" } ])
    end

    it "defaults js_errors to an empty array" do
      expect(create(:bug_report).js_errors).to eq([])
    end
  end
end
