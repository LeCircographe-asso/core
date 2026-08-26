# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Authentication
  include BreadcrumbsHelper
  include Pagy::Backend

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  allow_unauthenticated_access only: :url_not_found

  helper_method :bug_report_widget_enabled?

  # Catch-all cible de la route "*unmatched" (doit rester la dernière route de config/routes.rb).
  # Rend la même page 404 statique que Rails sert déjà par défaut, mais en passant par un
  # contrôleur : sans ça, un routage non trouvé ne déclenche jamais process_action.action_controller
  # et le reporting automatique de bugs (config/initializers/automatic_bug_reporting.rb) ne le
  # voit jamais.
  def url_not_found
    Support::AutomaticBugReportJob.perform_later(
      error_class: "ActionController::RoutingError",
      message: "No route matches #{request.fullpath}",
      kind: :not_found,
      path: request.fullpath,
      user_agent: request.user_agent,
      person_id: Current.user&.person_id,
      reporter_role: Current.user&.system_role
    )

    render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
  end

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
