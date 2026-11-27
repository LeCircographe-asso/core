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
    Current.session ||= check_idle_timeout(find_session_by_cookie)
  end

  def find_session_by_cookie
    session_id = cookies.signed[:session_id]
    return nil if session_id.blank?

    found = Session.find_by(id: session_id)
    if found.nil?
      cookies.delete(:session_id, **SESSION_COOKIE_OPTS)
      Rails.logger.warn(
        "[auth.audit] stale_session_cookie cookie_session_id=#{session_id} path=#{request.path} method=#{request.request_method}"
      )
      return nil
    end

    user = User.find_by(id: found.user_id)
    if user.nil? || user.deleted?
      reason = user.nil? ? "missing_user" : "user_deleted"
      db_session_id = found.id
      db_user_id = found.user_id
      found.destroy
      cookies.delete(:session_id, **SESSION_COOKIE_OPTS)
      Rails.logger.warn(
        "[auth.audit] invalid_session_cookie reason=#{reason} cookie_session_id=#{session_id} " \
        "db_session_id=#{db_session_id} user_id=#{db_user_id} path=#{request.path} method=#{request.request_method}"
      )
      return nil
    end

    found
  end

  def check_idle_timeout(found)
    return if found.nil?
    return expire_idle_session(found) if found.idle_expired?

    found.track_activity!
    found
  end

  def expire_idle_session(found)
    Rails.logger.info(
      "[auth.audit] idle_session_expired user_id=#{found.user_id} db_session_id=#{found.id} " \
      "idle_since=#{found.updated_at.iso8601} path=#{request.path}"
    )
    session[:reauth_email] = found.user.email_address
    @session_expired_for_inactivity = true
    found.destroy
    cookies.delete(:session_id, **SESSION_COOKIE_OPTS)
    nil
  end

  def request_authentication(alert: nil)
    store_return_location
    redirect_to new_session_path, alert: sign_in_alert(alert)
  end

  def sign_in_alert(default = nil)
    @session_expired_for_inactivity ? I18n.t("sessions.idle_expired_alert") : default
  end

  # A non-GET request (form submitted after the session expired) cannot be
  # replayed: send the user back to the page the form was on instead.
  def store_return_location
    return_url = request.get? ? request.url : request.referer
    return if return_url.blank?

    path = URI.parse(return_url).path.to_s.presence || "/"
    session[:return_to_after_authenticating] = return_url unless non_gettable_redirect_path?(path)
  rescue URI::InvalidURIError
    session[:return_to_after_authenticating] = request.url if request.get?
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
  ensure
    Current.session = nil
    cookies.delete(:session_id, **SESSION_COOKIE_OPTS)
  end
end
