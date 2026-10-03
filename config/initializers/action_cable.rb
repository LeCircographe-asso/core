# frozen_string_literal: true

Rails.application.configure do
  config.action_cable.mount_path = "/cable"
  config.action_cable.allowed_request_origins =
    if Rails.env.production? || Rails.env.staging?
      [ "https://lecircographe.fr", "https://staging.lecircographe.fr" ]
    else
      [ %r{http://localhost.*} ]
    end
end
