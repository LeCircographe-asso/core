# Middleware pour protéger l'environnement staging
class StagingAuth
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)

    # Skip auth for health check endpoint (Kamal needs this)
    if request.path == "/up"
      return @app.call(env)
    end

    # Vérifier si c'est l'environnement staging
    if staging_environment?(request)
      # Vérifier l'authentification HTTP Basic
      auth = Rack::Auth::Basic::Request.new(env)

      if auth.provided? && auth.basic? && auth.credentials
        username, password = auth.credentials

        if valid_credentials?(username, password)
          @app.call(env)
        else
          unauthorized_response
        end
      else
        unauthorized_response
      end
    else
      @app.call(env)
    end
  end

  private

  def staging_environment?(request)
    # Vérifier le sous-domaine ou la variable d'environnement
    request.host.start_with?("staging.") ||
    ENV["RAILS_ENV"] == "staging" ||
    ENV["STAGING_MODE"] == "true"
  end

  def valid_credentials?(username, password)
    username == "staging" &&
    password == ENV["STAGING_PASSWORD"] &&
    ENV["STAGING_PASSWORD"].present?
  end

  def unauthorized_response
    [
      401,
      {
        "WWW-Authenticate" => 'Basic realm="Staging Environment"',
        "Content-Type" => "text/html"
      },
      [ "<h1>Staging Environment - Authentication Required</h1><p>Please enter your staging credentials.</p>" ]
    ]
  end
end
