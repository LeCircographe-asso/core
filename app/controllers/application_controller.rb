# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Authentication
  include BreadcrumbsHelper
  include Pagy::Backend

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  allow_unauthenticated_access only: :url_not_found

  before_action :set_robots_header

  helper_method :bug_report_widget_enabled?, :robots_meta_content, :umami_website_id, :umami_session_replay_enabled?

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

  # Tant que Rails.application.config.x.seo_indexable est false (défaut), on
  # demande explicitement aux moteurs de recherche de ne pas indexer le site,
  # y compris les pages déjà connues d'eux (contrairement à robots.txt, qui ne
  # fait qu'empêcher un nouveau crawl sans désindexer l'existant).
  #
  # Une fois seo_indexable activé, seule seo_indexable_actions (config/application.rb)
  # devient indexable : volontairement limité à la home pour éviter que Google
  # affiche les pages publiques en Sitelinks sous le résultat principal.
  def set_robots_header
    return if seo_indexable_action?

    response.headers["X-Robots-Tag"] = "noindex, nofollow"
  end

  def seo_indexable_action?
    return false unless Rails.application.config.x.seo_indexable

    Rails.application.config.x.seo_indexable_actions.include?("#{controller_name}##{action_name}")
  end

  # Doublon du header X-Robots-Tag en balise <meta>, pour les cas où le header
  # HTTP n'est pas fiable (page servie par un cache/CDN statique sans repasser
  # par Rails). Les moteurs de recherche respectent les deux.
  def robots_meta_content
    seo_indexable_action? ? "index, follow" : "noindex, nofollow"
  end

  def bug_report_widget_enabled?
    BugReportWidgetSetting.current.enabled?
  end

  # Nil in development/test and whenever the site isn't configured yet in Umami's
  # admin — keeps the layout's script tag opt-in per environment without a separate
  # feature flag.
  def umami_website_id
    return nil unless Rails.env.staging? || Rails.env.production?

    Rails.application.credentials.dig(:umami, Rails.env.to_sym, :website_id)
  end

  # Session replay/heatmap captures on-screen interaction, not just page views —
  # deliberately staging-only until a privacy review clears it for production
  # (public forms can show personal data on screen). Not a credential: this is a
  # scope restriction to revisit in code, not a toggle to flip per environment.
  def umami_session_replay_enabled?
    Rails.env.staging?
  end

  def navigation_streams
    [
      turbo_stream.replace("navigation", render_to_string(partial: "shared/navbar")),
      turbo_stream.replace("flash", render_to_string(partial: "shared/flash"))
    ]
  end
end
