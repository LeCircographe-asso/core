# frozen_string_literal: true

require "rails_helper"

RSpec.describe Support::AutomaticBugReportJob do
  it "records an automatic BugReport" do
    expect do
      described_class.perform_now(error_class: "StandardError", message: "boom", kind: :error, path: "/x")
    end.to change(BugReport, :count).by(1)

    expect(BugReport.last).to be_automatic
  end

  it "never lets a reporting failure bubble up" do
    allow(BugReport).to receive(:record_automatic!).and_raise(StandardError, "db down")

    expect do
      described_class.perform_now(error_class: "StandardError", message: "boom", kind: :error, path: "/x")
    end.not_to raise_error
  end
end
