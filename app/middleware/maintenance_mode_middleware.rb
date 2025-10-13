class MaintenanceModeMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)

    # 1. Toujours autoriser healthcheck (pour Kamal)
    return @app.call(env) if healthcheck?(request)

    # 2. Toujours autoriser les assets (CSS, JS, images, fonts)
    return @app.call(env) if asset_request?(request)

    # 3. Si maintenance désactivée, tout passe
    return @app.call(env) unless maintenance_enabled?

    # 4. Autoriser admin connecté et page login
    return @app.call(env) if admin_access?(env, request)

    # 4. Sinon, page maintenance pour visiteurs
    maintenance_response
  end

  private

  def maintenance_enabled?
    # Logique hybride : maintenance par défaut si ENV non défini (comme maintenance-mode)
    # mais support du fichier /tmp/maintenance pour plus de flexibilité
    value = ENV["MAINTENANCE_MODE"]

    # Si ENV["MAINTENANCE_MODE"] n'est pas défini, désactivation par défaut
    return false if value.nil? || value.to_s.strip.empty?

    # Si ENV est défini, respecter sa valeur
    env_enabled = value.to_s.strip.casecmp("true").zero?

    # Vérifier aussi le fichier /tmp/maintenance pour plus de flexibilité
    file_enabled = File.exist?("/tmp/maintenance") && File.read("/tmp/maintenance").strip.downcase == "true"

    env_enabled || file_enabled
  end

  def healthcheck?(request)
    request.path == "/up"
  end

  def asset_request?(request)
    # Autoriser tous les assets (CSS, JS, images, fonts, etc.)
    request.path.start_with?("/assets/") ||
    request.path.start_with?("/packs/") ||
    request.path.match?(/\.(css|js|png|jpg|jpeg|gif|svg|woff|woff2|ttf|eot|ico)$/i)
  end

  def admin_access?(env, request)
    # Autoriser pages login (public et admin) pour que les admins puissent se connecter
    # Public: /session/new, /session (POST pour login)
    # Admin: /admin/session/new, /admin/session (POST pour login)
    return true if request.path.start_with?("/session")
    return true if request.path.start_with?("/admin/session")

    # Autoriser l'accès admin maintenance (auth simple)
    return true if request.path.start_with?("/admin/maintenance")

    # Autoriser toutes les routes admin si session admin valide
    if request.path.start_with?("/admin")
      session = load_session(env)
      Rails.logger.debug("MaintenanceMode: Checking admin access - path: #{request.path}, user_id: #{session['user_id']}")
      return session && session["user_id"].present?
    end

    false
  end

  def load_session(env)
    # Charger la session Rails depuis les cookies
    session_key = Rails.application.config.session_options[:key] || "_circographe_session"

    # Créer un cookie jar pour lire les cookies chiffrés
    cookie_jar = ActionDispatch::Cookies::CookieJar.build(
      Rack::Request.new(env),
      Rails.application.config.session_options
    )

    # Récupérer la session chiffrée
    session_data = cookie_jar.encrypted[session_key]
    session_data.is_a?(Hash) ? session_data : {}
  rescue StandardError => e
    Rails.logger.error("MaintenanceMode: Erreur chargement session - #{e.message}")
    {}
  end

  def maintenance_response
    logo_src = inline_asset_data("Le-Circographe-crop.webp") || asset_path("Le-Circographe-crop.webp")

    # Headers de sécurité pour forcer HTTPS et éviter les warnings
    headers = {
      "Content-Type" => "text/html; charset=utf-8",
      "Strict-Transport-Security" => "max-age=31536000; includeSubDomains",
      "Content-Security-Policy" => "default-src 'self' https:; img-src 'self' data: https:; style-src 'self' 'unsafe-inline'; script-src 'self'; connect-src 'self'"
    }

    body = <<~HTML
      <!DOCTYPE html>
      <html lang="fr">
        <head>
          <meta charset="utf-8" />
          <meta name="viewport" content="width=device-width, initial-scale=1" />
          <title>Le site est en maintenance</title>
          <style>
            /* Contraste et lisibilité renforcés + tailles cohérentes */
            :root { --bg: #f7fafc; --panel: #ffffff; --text: #0b1220; --muted: #334155; --border: #cbd5e1; --accent: #1f5c55; --accent-dark: #164742; }
            * { box-sizing: border-box }
            body { font-family: ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial, Noto Sans, "Apple Color Emoji", "Segoe UI Emoji"; margin: 0; padding: 24px; background: var(--bg); color: var(--text); display: flex; align-items: center; justify-content: center; min-height: 100vh; }
            .card { width: 100%; max-width: 840px; background: var(--panel); border: 1px solid var(--border); border-radius: 16px; padding: clamp(20px, 3vw, 36px); box-shadow: 0 16px 48px rgba(2,6,23,.06); text-align: center; }
            .logo {
              width: clamp(160px, 22vw, 260px);
              height: auto;
              display: inline-block;
              margin-bottom: 16px;
              object-fit: contain;
            }
            .brand { font-weight: 800; letter-spacing: .2px; color: var(--text); font-size: clamp(1rem, 1.1vw + .7rem, 1.15rem); margin-bottom: 6px; }
            h1 { margin: 0 0 12px; line-height: 1.2; font-weight: 800; font-size: clamp(1.8rem, 2.6vw + 1rem, 2.6rem); }
            p.lead { margin: 0 6px 22px; color: var(--muted); font-size: clamp(1rem, .4vw + .9rem, 1.08rem); }
            .pill { display: inline-block; background: rgba(31,92,85,0.10); color: var(--accent); border: 1px solid rgba(31,92,85,0.55); border-radius: 999px; padding: 7px 14px; font-size: .92rem; margin-bottom: 16px; font-weight: 700; }
            .actions { display: grid; gap: 14px; margin-top: 20px; }
            .actions.social { grid-template-columns: 1fr; }
            @media (min-width: 640px) { .actions.social { grid-template-columns: repeat(3, 1fr) } }
            .actions.google { grid-template-columns: 1fr; margin-top: 16px; }
            .btn { display: inline-flex; align-items: center; justify-content: center; gap: 10px; height: 56px; padding: 0 18px; border-radius: 12px; text-decoration: none; font-weight: 800; font-size: 1rem; border: 2px solid var(--border); color: var(--text); background: #ffffff; transition: transform .06s ease, background .2s ease, border-color .2s ease; }
            .btn:hover { transform: translateY(-1px); border-color: #94a3b8; background: #f1f5f9; }
      #{'      '}
            /* Bouton login admin caché - zone invisible mais détectable */
            .admin-login-btn {
              position: absolute;
              top: 20px;
              right: 20px;
              opacity: 0;
              transition: opacity 0.3s ease;
              background: transparent;
              color: transparent;
              border: none;
              padding: 8px 16px;
              border-radius: 8px;
              font-size: 0.9rem;
              font-weight: 600;
              cursor: pointer;
              text-decoration: none;
              display: inline-block;
              z-index: 10;
              width: 80px;
              height: 36px;
              /* Zone cliquable invisible mais détectable */
              pointer-events: auto;
            }
            /* Visible SEULEMENT quand on hover LE BOUTON LUI-MÊME */
            .admin-login-btn:hover {
              opacity: 1;
              background: var(--accent);
              color: white;
              transform: translateY(-1px);
            }
            .btn.primary { background: var(--accent); color: #ffffff; border-color: var(--accent); }
            .btn.primary:hover { background: var(--accent-dark); border-color: var(--accent-dark); }
            .small { font-size: .86rem; color: #5b677a; margin-top: 22px; }
            .icon { width: 22px; height: 22px; display: inline-block; overflow: visible; }
          </style>
        </head>
        <body>
          <div class="card">
            <!-- Bouton accès admin caché -->
            <a href="/admin/maintenance" class="admin-login-btn">Admin</a>
      #{'      '}
            <img class="logo" src="#{logo_src}" alt="Logo Le Circographe" width="72" height="72" />
            <div class="brand">Le Circographe</div>
            <div class="pill" aria-live="polite">Maintenance en cours</div>
            <h1>Nous revenons très vite</h1>
            <p class="lead">Merci pour votre patience. En attendant, retrouvez‑nous sur nos réseaux&nbsp;:</p>

            <!-- Horaires d'ouverture -->
            #{opening_hours_section}

            <div class="actions social">
              <a class="btn" href="#{instagram_url}" target="_blank" rel="noopener" aria-label="Nous suivre sur Instagram">
                <svg class="icon" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true"><path d="M7 2h10a5 5 0 0 1 5 5v10a5 5 0 0 1-5 5H7a5 5 0 0 1-5-5V7a5 5 0 0 1 5-5z" stroke="#1f2937" stroke-width="1.5"/><path d="M12 8.5a3.5 3.5 0 1 0 0 7 3.5 3.5 0 0 0 0-7z" stroke="#1f2937" stroke-width="1.5"/><circle cx="17.5" cy="6.5" r="1.25" fill="#1f2937"/></svg>
                Instagram
              </a>
              <a class="btn" href="#{whatsapp_url}" target="_blank" rel="noopener" aria-label="Rejoindre notre groupe WhatsApp">
                <svg class="icon" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
                  <path fill="#25D366" d="M12.04 2.01c-5.51 0-9.98 4.46-9.98 9.96 0 1.76.46 3.4 1.26 4.83L2 22l5.33-1.38c1.38.75 2.97 1.18 4.66 1.18 5.51 0 9.98-4.46 9.98-9.96s-4.47-9.83-9.93-9.83h-.01z"/>
                  <path fill="#fff" d="M17.57 14.45c-.1.27-.58.53-.82.57-.22.04-.5.08-.81-.05-.19-.08-.43-.15-.74-.3-1.3-.57-2.14-1.01-3.05-1.94-.24-.26-.58-.67-.83-1.06-.23-.36-.37-.65-.5-.92-.13-.27-.03-.6.1-.84.12-.23.28-.53.42-.68.14-.15.23-.23.33-.23h.24c.08 0 .18 0 .27.2.1.23.34.8.38.86.03.07.06.15.01.24-.05.1-.08.16-.16.25l-.12.14c-.08.08-.16.17-.07.33.1.16.45.74 1.06 1.2.73.55 1.35.73 1.55.82.2.08.31.06.43-.04.12-.1.5-.58.63-.78.13-.2.27-.17.45-.1.19.07 1.18.56 1.38.66.2.1.33.15.38.23.05.08.05.49-.05.76z"/>
                </svg>
                WhatsApp
              </a>
              <a class="btn" href="#{facebook_url}" target="_blank" rel="noopener" aria-label="Nous suivre sur Facebook">
                <svg class="icon" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true"><path d="M14 9h3V6h-3c-1.7 0-3 1.3-3 3v2H8v3h3v7h3v-7h3l1-3h-4V9c0-.6.4-1 1-1z" fill="#1f2937"/></svg>
                Facebook
              </a>
            </div>

            <div class="actions google">
              <a class="btn primary" href="#{google_url}" target="_blank" rel="noopener" aria-label="Laisser un avis Google">
                <svg class="icon" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" aria-hidden="true"><path fill="#fff" d="M21.35 11.1H12v2.9h5.3c-.23 1.47-1.6 4.3-5.3 4.3-3.2 0-5.8-2.65-5.8-5.9s2.6-5.9 5.8-5.9c1.83 0 3.05.78 3.75 1.45l2.56-2.47C16.6 3.45 14.5 2.5 12 2.5 6.98 2.5 2.9 6.58 2.9 11.6s4.08 9.1 9.1 9.1c5.25 0 8.7-3.68 8.7-8.86 0-.6-.06-1.06-.15-1.74z"/></svg>
                Laisser un avis Google
              </a>
            </div>
      #{'      '}
          </div>
        </body>
      </html>
    HTML

    # Fusionner avec les headers de sécurité définis plus haut
    headers.merge!({
      "Cache-Control" => "no-store, no-cache, must-revalidate, max-age=0",
      "Retry-After" => "300"
    })

    [ 503, headers, [ body ] ]
  end

  def google_url
    url = ENV["GOOGLE_PAGE_URL"].to_s.strip
    url.empty? ? "https://share.google/ljLBRjVB5FoNNJV3o" : url
  end

  def instagram_url
    url = ENV["INSTAGRAM_URL"].to_s.strip
    url.empty? ? "https://www.instagram.com/lecircographe/?hl=fr" : url
  end

  def whatsapp_url
    url = ENV["WHATSAPP_COMMUNITY_URL"].to_s.strip
    url.empty? ? "https://chat.whatsapp.com/HUd6jvELxqVD642vfgVXBq" : url
  end

  def facebook_url
    url = ENV["FACEBOOK_URL"].to_s.strip
    url.empty? ? "https://www.facebook.com/lecircographe" : url
  end

  def opening_hours_section
    # Utiliser le système de fichier JSON robuste
    begin
      file_path = Rails.root.join("storage", "opening_hours.json")
      if File.exist?(file_path)
        horaires = JSON.parse(File.read(file_path)).symbolize_keys
      else
        horaires = OpeningHoursHelper.default_opening_hours
      end
    rescue => e
      # Fallback en cas d'erreur
      horaires = OpeningHoursHelper.default_opening_hours
    end

    html = '<div style="margin: 20px 0; padding: 16px; background: rgba(31,92,85,0.05); border-radius: 12px; border: 1px solid rgba(31,92,85,0.15);">'
    html += '<h3 style="margin: 0 0 12px; font-size: 1.1rem; font-weight: 700; color: var(--accent);">Horaires d\'ouverture</h3>'
    html += '<div style="font-size: 0.95rem; line-height: 1.6; color: var(--muted);">'

    horaires.each do |day, hours|
      day_name = day.to_s.capitalize
      html += "<div><strong>#{day_name}:</strong> #{hours}</div>"
    end

    html += "</div></div>"
    html
  end

  # Auto-redirect supprimé selon la demande
  def auto_redirect_meta
    ""
  end

  def asset_path(name)
    ActionController::Base.helpers.asset_path(name)
  rescue StandardError
    "/assets/#{name}"
  end

  def inline_asset_data(name)
    path = File.join(Rails.root.to_s, "app", "assets", "images", name)
    return nil unless File.file?(path)

    mime = case File.extname(name).downcase
    when ".webp" then "image/webp"
    when ".png" then "image/png"
    when ".jpg", ".jpeg" then "image/jpeg"
    when ".svg" then "image/svg+xml"
    else "application/octet-stream"
    end

    data = ::Base64.strict_encode64(File.binread(path))
    "data:#{mime};base64,#{data}"
  rescue StandardError
    nil
  end
end
