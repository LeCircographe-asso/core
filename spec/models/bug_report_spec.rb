# frozen_string_literal: true

require "rails_helper"

RSpec.describe BugReport, type: :model do
  include ActiveSupport::Testing::TimeHelpers

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

  describe ".record_automatic!" do
    it "creates an automatic report on the first occurrence" do
      report = BugReport.record_automatic!(
        error_class: "ActiveRecord::RecordNotFound",
        message: "Couldn't find Event with 'id'=999",
        kind: :error,
        path: "/events/999",
        backtrace: [ "app/controllers/events_controller.rb:11" ]
      )

      expect(report).to be_automatic
      expect(report.occurrence_count).to eq(1)
      expect(report.note).to eq("Erreur serveur (ActiveRecord::RecordNotFound) : /events/999")
      expect(report.js_errors.first["type"]).to eq("server_error")
      expect(report.js_errors.first["stack"]).to include("events_controller.rb")
    end

    it "labels a routing miss distinctly from a server error" do
      report = BugReport.record_automatic!(error_class: "ActionController::RoutingError", message: "No route matches /bogus", kind: :not_found, path: "/bogus")

      expect(report.note).to eq("Page introuvable (404) : /bogus")
    end

    it "increments occurrence_count instead of duplicating within the dedup window" do
      first = BugReport.record_automatic!(error_class: "StandardError", message: "boom", kind: :error, path: "/x")
      second = BugReport.record_automatic!(error_class: "StandardError", message: "boom (again)", kind: :error, path: "/x")

      expect(second.id).to eq(first.id)
      expect(second.occurrence_count).to eq(2)
      expect(BugReport.count).to eq(1)
    end

    it "groups occurrences across different record ids at the same route" do
      BugReport.record_automatic!(error_class: "ActiveRecord::RecordNotFound", message: "boom", kind: :error, path: "/events/111")
      report = BugReport.record_automatic!(error_class: "ActiveRecord::RecordNotFound", message: "boom", kind: :error, path: "/events/222")

      expect(BugReport.count).to eq(1)
      expect(report.occurrence_count).to eq(2)
    end

    it "starts a new report once the dedup window has passed" do
      travel_to 20.minutes.ago do
        BugReport.record_automatic!(error_class: "StandardError", message: "boom", kind: :error, path: "/x")
      end

      BugReport.record_automatic!(error_class: "StandardError", message: "boom", kind: :error, path: "/x")

      expect(BugReport.count).to eq(2)
    end

    it "ignores known-noise exceptions" do
      report = BugReport.record_automatic!(error_class: "ActionController::InvalidAuthenticityToken", message: "boom", kind: :error, path: "/x")

      expect(report).to be_nil
      expect(BugReport.count).to eq(0)
    end
  end
end
