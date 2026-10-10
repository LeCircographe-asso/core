# frozen_string_literal: true

OmniAuth.config.test_mode = true
OmniAuth.config.logger = Rails.logger

RSpec.configure do |config|
  config.after do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end
end

def mock_google_auth(email:, first_name: "Jean", last_name: "Dupont", uid: "1234567890")
  OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
    provider: "google_oauth2",
    uid: uid,
    info: OmniAuth::AuthHash::InfoHash.new(
      email: email,
      first_name: first_name,
      last_name: last_name,
      name: "#{first_name} #{last_name}"
    )
  )
  Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:google_oauth2]
end
