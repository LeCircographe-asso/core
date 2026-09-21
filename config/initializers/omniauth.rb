# frozen_string_literal: true

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
    ENV["GOOGLE_CLIENT_ID"],
    ENV["GOOGLE_CLIENT_SECRET"],
    scope: "email,profile",
    prompt: "select_account"
end

OmniAuth.config.allowed_request_methods = [ :post ]
OmniAuth.config.silence_get_warning = true

# En test, la requête est simulée via OmniAuth.config.mock_auth (voir spec/support/omniauth.rb).
OmniAuth.config.test_mode = true if Rails.env.test?
