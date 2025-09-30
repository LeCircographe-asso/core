class MaintenanceModeMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    if maintenance_enabled? && !healthcheck?(env)
      return maintenance_response
    end

    @app.call(env)
  end

  private

  def maintenance_enabled?
    ENV["MAINTENANCE_MODE"].to_s.strip.casecmp("true").zero?
  end

  def healthcheck?(env)
    request = Rack::Request.new(env)
    request.path == "/up"
  end

  def maintenance_response
    body = <<~HTML
      <!DOCTYPE html>
      <html lang="fr">
        <head>
          <meta charset="utf-8" />
          <meta name="viewport" content="width=device-width, initial-scale=1" />
          <title>Le site est en maintenance</title>
          <style>
            :root { --bg: #fff8f8; --panel: #ffffff; --text: #0f172a; --muted: #475569; --border: #e5e7eb; --accent: #1f5c55; }
            * { box-sizing: border-box }
            body { font-family: ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial, Noto Sans, "Apple Color Emoji", "Segoe UI Emoji"; margin: 0; padding: 24px; background: var(--bg); color: var(--text); display: flex; align-items: center; justify-content: center; min-height: 100vh; }
            .card { width: 100%; max-width: 720px; background: var(--panel); border: 1px solid var(--border); border-radius: 16px; padding: 28px; box-shadow: 0 10px 30px rgba(0,0,0,.06); text-align: center; }
            .brand { font-weight: 700; letter-spacing: .25px; color: var(--muted); font-size: .95rem; text-transform: uppercase; margin-bottom: 6px; }
            h1 { margin: 0 0 8px; font-size: clamp(1.5rem, 2.8vw + 1rem, 2.2rem); }
            p.lead { margin: 0 0 16px; color: var(--muted); }
            .pill { display: inline-block; background: rgba(31,92,85,0.08); color: var(--accent); border: 1px solid rgba(31,92,85,0.35); border-radius: 999px; padding: 6px 12px; font-size: .9rem; margin-bottom: 16px; }
            .actions { display: grid; grid-template-columns: 1fr; gap: 10px; margin-top: 16px; }
            @media (min-width: 520px) { .actions { grid-template-columns: repeat(3, 1fr) } }
            .btn { display: inline-flex; align-items: center; justify-content: center; gap: 8px; padding: 12px 14px; border-radius: 10px; text-decoration: none; font-weight: 600; border: 1px solid var(--border); color: var(--text); background: #f8fafc; transition: transform .06s ease, background .2s ease, border-color .2s ease; }
            .btn:hover { transform: translateY(-1px); border-color: #cbd5e1; background: #eef2f7; }
            .btn.primary { background: var(--accent); color: #ffffff; border-color: var(--accent); }
            .btn.primary:hover { background: #1a4d49; border-color: #1a4d49; }
            .note { margin-top: 14px; font-size: .95rem; color: var(--muted); }
            .small { font-size: .82rem; color: #64748b; margin-top: 22px; }
          </style>
        </head>
        <body>
          <div class="card">
            <div class="brand">Le Circographe</div>
            <div class="pill">Maintenance en cours</div>
            <h1>On revient très vite</h1>
            <p class="lead">Merci pour votre patience. En attendant&nbsp;:</p>

            <div class="actions">
              <a class="btn primary" href="#{google_url}" target="_blank" rel="noopener">Laisser un avis Google</a>
              <a class="btn" href="#{instagram_url}" target="_blank" rel="noopener">Voir nos horaires sur Instagram</a>
              <a class="btn" href="#{whatsapp_url}" target="_blank" rel="noopener">Rejoindre le groupe WhatsApp</a>
            </div>

            <p class="note">Les horaires sont toujours postés sur Instagram et notre groupe communautaire WhatsApp.</p>
            <p class="small">Code 503 avec en‑tête Retry‑After pour indiquer une maintenance temporaire.</p>
          </div>
        </body>
      </html>
    HTML

    headers = {
      "Content-Type" => "text/html; charset=utf-8",
      "Cache-Control" => "no-store, no-cache, must-revalidate, max-age=0",
      "Retry-After" => "300"
    }

    [503, headers, [body]]
  end

  def google_url
    ENV["GOOGLE_PAGE_URL"].to_s.strip.empty? ? "#" : ENV["GOOGLE_PAGE_URL"].to_s
  end

  def instagram_url
    ENV["INSTAGRAM_URL"].to_s.strip.empty? ? "#" : ENV["INSTAGRAM_URL"].to_s
  end

  def whatsapp_url
    ENV["WHATSAPP_COMMUNITY_URL"].to_s.strip.empty? ? "#" : ENV["WHATSAPP_COMMUNITY_URL"].to_s
  end

  # Auto-redirect supprimé selon la demande
  def auto_redirect_meta
    ""
  end
end


