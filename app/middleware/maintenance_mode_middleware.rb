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
          <title>Maintenance</title>
          <style>
            body { font-family: system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial, Noto Sans, "Apple Color Emoji", "Segoe UI Emoji"; margin: 0; padding: 0; background: #0f172a; color: #e2e8f0; display: flex; align-items: center; justify-content: center; min-height: 100vh; }
            .card { text-align: center; padding: 2rem; background: #111827; border: 1px solid #334155; border-radius: 12px; max-width: 560px; box-shadow: 0 10px 30px rgba(0,0,0,.35); }
            h1 { margin: 0 0 0.5rem; font-size: 1.75rem; }
            p { margin: 0.25rem 0; color: #cbd5e1; }
          </style>
        </head>
        <body>
          <div class="card">
            <h1>Site en maintenance</h1>
            <p>Nous revenons très vite. Merci pour votre patience.</p>
          </div>
        </body>
      </html>
    HTML

    headers = {
      "Content-Type" => "text/html; charset=utf-8",
      "Cache-Control" => "no-store, no-cache, must-revalidate, max-age=0"
    }

    [503, headers, [body]]
  end
end


