# Be sure to restart your server when you modify this file.

# Configure CORS headers for font files to ensure they load properly in all browsers
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "*"
    resource "/assets/*",
      headers: :any,
      methods: [ :get, :options ]
  end
end
