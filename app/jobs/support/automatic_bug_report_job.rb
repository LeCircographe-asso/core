# frozen_string_literal: true

module Support
  class AutomaticBugReportJob < ApplicationJob
    queue_as :default

    def perform(error_class:, message:, kind:, path: nil, backtrace: nil, user_agent: nil, person_id: nil, reporter_role: nil)
      BugReport.record_automatic!(
        error_class: error_class,
        message: message,
        kind: kind,
        path: path,
        backtrace: backtrace,
        user_agent: user_agent,
        person_id: person_id,
        reporter_role: reporter_role
      )
    rescue StandardError => e
      # Le reporting ne doit jamais devenir lui-même une source de pannes en arrière-plan.
      Rails.logger.error("[Support::AutomaticBugReportJob] #{e.class}: #{e.message}")
    end
  end
end
