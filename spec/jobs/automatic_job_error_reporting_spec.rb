# frozen_string_literal: true

require "rails_helper"

# config/initializers/automatic_bug_reporting.rb : un job en échec non géré doit remonter
# dans BugReport (écran admin "Rapports de bug"), comme une erreur 500 de requête.
RSpec.describe "Automatic bug reporting for failed jobs" do
  let(:failing_job) do
    Class.new(ApplicationJob) do
      def self.name = "FailingSpecJob"

      def perform
        raise ArgumentError, "kaboom"
      end
    end
  end

  it "enqueues an automatic bug report when a job raises" do
    expect do
      failing_job.perform_now
    rescue ArgumentError
      nil
    end.to have_enqueued_job(Support::AutomaticBugReportJob).with(
      hash_including(error_class: "ArgumentError", message: "kaboom", kind: :job_error, path: "job:FailingSpecJob")
    )
  end

  it "does not report an exception absorbed by retry_on" do
    retried_job = Class.new(ApplicationJob) do
      def self.name = "RetriedSpecJob"

      retry_on ArgumentError, attempts: 3

      def perform
        raise ArgumentError, "temporary"
      end
    end

    expect { retried_job.perform_now }.not_to have_enqueued_job(Support::AutomaticBugReportJob)
  end

  it "never reports a failure of the reporting job itself" do
    expect do
      ActiveSupport::Notifications.instrument(
        "perform.active_job",
        job: Support::AutomaticBugReportJob.new,
        exception_object: StandardError.new("db down")
      )
    end.not_to have_enqueued_job(Support::AutomaticBugReportJob)
  end
end
