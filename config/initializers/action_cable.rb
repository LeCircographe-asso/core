# Configure Action Cable
Rails.application.configure do
  config.action_cable.mount_path = "/cable"

  # Adapter configuration (Rails 8 uses solid_cable by default)
  # solid_cable is already configured in config/cable.yml

  # Allow all origins in development/test, restrict in production via cable.yml
  if Rails.env.development? || Rails.env.test?
    config.action_cable.url = "ws://localhost:3000/cable"
    config.action_cable.allowed_request_origins = [ /http:\/\/localhost.*/ ]
  end
end
