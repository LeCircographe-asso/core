# frozen_string_literal: true

module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**)
      skip_before_action(:require_authentication, **)
    end
  end

  def current_user
    Current.user if authenticated?
  end

  private

  def authenticated?
    resume_session
  end

  def require_authentication
    resume_session || request_authentication
  end

  def resume_session
    Current.session ||= find_session_by_cookie
  end

  def find_session_by_cookie
    session_id = cookies.signed[:session_id]
    return nil if session_id.blank?

    Session.find_by(id: session_id)
  end

  def request_authentication
    begin
      uri = URI.parse(request.url)
      path = uri.path.to_s.presence || "/"
      session[:return_to_after_authenticating] = request.url unless non_gettable_redirect_path?(path)
    rescue URI::InvalidURIError
      session[:return_to_after_authenticating] = request.url
    end

    redirect_to new_session_path
  end

  # Cible après login : ne jamais rediriger vers une URL en GET qui n'existe pas
  # (ex. /session et /registration sont POST-only → 303 après POST créait GET /session → RoutingError).
  def after_authentication_url
    stored = session.delete(:return_to_after_authenticating)
    safe_url_after_authentication(stored)
  end

  def safe_url_after_authentication(stored)
    return root_path if stored.blank?

    uri = URI.parse(stored.to_s.strip)

    if uri.host.present?
      return root_path unless uri.host == request.host && uri.port == request.port
    end

    path = uri.path.to_s
    path = "/" if path.blank?
    return root_path if non_gettable_redirect_path?(path)

    stored.to_s
  rescue URI::InvalidURIError
    root_path
  end

  def non_gettable_redirect_path?(path)
    path == "/session" || path == "/registration"
  end

  # Même jeu d’options à la pose et à la suppression du cookie (évite un cookie « mort »).
  SESSION_COOKIE_OPTS = { httponly: true, same_site: :lax, path: "/" }.freeze

  def start_new_session_for(user)
    user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
      Current.session = session
      cookies.signed.permanent[:session_id] = { value: session.id, **SESSION_COOKIE_OPTS }
    end
  end

  def terminate_session
    Current.session&.destroy
    Current.session = nil
    cookies.delete(:session_id, **SESSION_COOKIE_OPTS)
  end
end
