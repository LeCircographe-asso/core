# frozen_string_literal: true

class BugReportsController < ApplicationController
  allow_unauthenticated_access only: :create

  rate_limit to: 5, within: 15.minutes, only: :create,
              with: -> { respond_with_bug_report_error(I18n.t("bug_reports.create.rate_limited")) }

  def create
    result = Support::BugReportSubmitter.new(
      note: params[:note],
      page_url: request.referer,
      user_agent: request.user_agent,
      person_id: current_user&.person_id,
      screenshot: params[:screenshot]
    ).call

    if result.success?
      render turbo_stream: turbo_stream.update("bug_report_modal_body",
        partial: "bug_reports/success")
    else
      respond_with_bug_report_error(result.message)
    end
  end

  private

  def respond_with_bug_report_error(message)
    render turbo_stream: turbo_stream.update("bug_report_modal_body",
      partial: "bug_reports/form", locals: { note: params[:note], error: message })
  end
end
