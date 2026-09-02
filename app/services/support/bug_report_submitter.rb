# frozen_string_literal: true

module Support
  # Les champs device_type/display_mode/viewport/js_errors viennent du JS client
  # (bug_report_controller.js) — jamais fiables, toujours passés à la validation
  # du modèle (enum) plutôt qu'assignés en confiance, et js_errors est nettoyé/
  # borné ici avant stockage.
  class BugReportSubmitter < BaseService
    MAX_JS_ERRORS = 20
    MAX_FIELD_LENGTH = 500
    JS_ERROR_KEYS = %w[type message source line col stack at_ms].freeze

    attribute :note, :string
    attribute :page_url, :string
    attribute :user_agent, :string
    attribute :person_id, :integer
    attribute :device_type, :string
    attribute :display_mode, :string
    attribute :viewport_width, :integer
    attribute :viewport_height, :integer
    attribute :reporter_role, :string
    attribute :js_errors_json, :string

    attr_accessor :screenshot

    validates :note, presence: true

    def call
      return failure(I18n.t("services.validation.invalid_data_with_details", details: errors.full_messages.join(", "))) unless valid?

      bug_report = BugReport.new(
        note: note,
        page_url: page_url,
        user_agent: user_agent,
        person_id: person_id,
        device_type: device_type.presence,
        display_mode: display_mode.presence,
        viewport_width: viewport_width,
        viewport_height: viewport_height,
        reporter_role: reporter_role.presence,
        js_errors: sanitized_js_errors
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

    private

    def sanitized_js_errors
      return [] if js_errors_json.blank?

      parsed = JSON.parse(js_errors_json)
      return [] unless parsed.is_a?(Array)

      parsed.first(MAX_JS_ERRORS).filter_map do |entry|
        next unless entry.is_a?(Hash)

        entry.slice(*JS_ERROR_KEYS).transform_values { |v| v.is_a?(String) ? v.first(MAX_FIELD_LENGTH) : v }
      end
    rescue JSON::ParserError
      []
    end
  end
end
