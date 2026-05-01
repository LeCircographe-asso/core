# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Authentication
  include BreadcrumbsHelper
  include Pagy::Backend

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :dev_quick_login_nav_visible?

  private

  # Menu « Connexion rapide (dev) » : super-admin ou session prolongée après impersonation (voir Dev::QuickLoginController).
  def dev_quick_login_nav_visible?
    return false unless Rails.env.development? && authenticated?

    return true if Current.user.super_admin?

    gid = session[Dev::QuickLoginController::GRANTER_SESSION_KEY]
    gid.present? && User.exists?(id: gid, system_role: User.system_roles[:super_admin])
  end

  def navigation_streams
    [
      turbo_stream.replace("navigation", render_to_string(partial: "shared/navbar")),
      turbo_stream.replace("flash", render_to_string(partial: "shared/flash"))
    ]
  end
end
