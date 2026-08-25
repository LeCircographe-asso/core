# frozen_string_literal: true

module Support
  class BugReportSubmitter < BaseService
    attribute :note, :string
    attribute :page_url, :string
    attribute :user_agent, :string
    attribute :person_id, :integer

    attr_accessor :screenshot

    validates :note, presence: true

    def call
      return failure(I18n.t("services.validation.invalid_data_with_details", details: errors.full_messages.join(", "))) unless valid?

      bug_report = BugReport.new(
        note: note,
        page_url: page_url,
        user_agent: user_agent,
        person_id: person_id
      )
      bug_report.screenshot.attach(screenshot) if screenshot.present?

      if bug_report.save
        ActiveSupport::Notifications.instrument(
          "support.bug_report_submitted",
          bug_report_id: bug_report.id,
          person_id: person_id
        )

        success(message: I18n.t("bug_reports.create.success"), bug_report: bug_report)
      else
        failure(bug_report.errors.full_messages.join(", "))
      end
    rescue StandardError => e
      Rails.logger.error "[Support::BugReportSubmitter] Error: #{e.message}"
      failure(I18n.t("bug_reports.create.error"))
    end
  end
end
