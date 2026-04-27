Rails.application.configure do
  config.action_cable.mount_path = "/cable"
  config.action_cable.allowed_request_origins = [ /http:\/\/localhost.*/ ]
end
