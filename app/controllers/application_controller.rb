# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Authentication
  include BreadcrumbsHelper
  include Pagy::Backend

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :bug_report_widget_enabled?

  private

  def bug_report_widget_enabled?
    BugReportWidgetSetting.current.enabled?
  end

  def navigation_streams
    [
      turbo_stream.replace("navigation", render_to_string(partial: "shared/navbar")),
      turbo_stream.replace("flash", render_to_string(partial: "shared/flash"))
    ]
  end
end
