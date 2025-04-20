# Configure Action Cable to use SQLite
Rails.application.configure do
  config.action_cable.mount_path = '/cable'
  config.action_cable.url = 'ws://localhost:3000/cable'
  config.action_cable.allowed_request_origins = [ /http:\/\/localhost.*/ ]
  
  # Use SQLite for Action Cable in production
  if Rails.env.production?
    config.action_cable.connect_via = { 
      writing: :cable, 
      reading: :cable 
    }
  end
end 