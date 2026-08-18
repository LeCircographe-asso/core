# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    # Default: only allow same-origin resources
    policy.default_src :self

    # Scripts: self only (SweetAlert2/jsdelivr removed — no call site, unused)
    policy.script_src :self, :unsafe_inline

    # Styles: self + CDN (FontAwesome, Leaflet)
    policy.style_src :self, :unsafe_inline, "cdn.jsdelivr.net", "cdnjs.cloudflare.com"

    # Fonts: self + CDN (FontAwesome)
    policy.font_src :self, :data, "cdnjs.cloudflare.com"

    # Images: self + https external (Unsplash placeholders)
    policy.img_src :self, :data, :https

    # No flash/applets/plugins
    policy.object_src :none

    # Allow WebSocket connections for Turbo Cable + external APIs (address autocomplete)
    policy.connect_src :self, :wss, "api-adresse.data.gouv.fr"

    # Frame ancestors: only allow same-origin (prevent clickjacking)
    policy.frame_ancestors :self
  end

  # Generate session nonces for permitted importmap, inline scripts, and inline styles.
  # Rails 8.1 automatically adds nonce to <script> and <style> tags
  #
  # request.session.id is nil until something writes to the session (Rack lazily
  # assigns it). Beyond the malformed-header risk this alone would cause, it also
  # breaks Turbo: the browser keeps enforcing the CSP header from the very first
  # full page load for the whole Turbo-driven visit (later fetch()-based page
  # swaps don't get to install a new CSP). A first-time visitor's first page
  # would get a one-off random nonce (no session yet), then every Turbo-navigated
  # page after it gets the now-established session nonce instead — permanently
  # mismatched against the frozen first-page policy until an actual reload.
  # Writing a throwaway key forces Rack to assign the id synchronously, so even
  # the very first request already gets the stable, session-based nonce.
  config.content_security_policy_nonce_generator = ->(request) {
    request.session[:_csp_nonce_seed] ||= true
    request.session.id.to_s.presence || SecureRandom.base64(16)
  }
  config.content_security_policy_nonce_directives = %w[script-src style-src]

  # Uncomment to test CSP violations without blocking (only log them)
  # config.content_security_policy_report_only = true
end
