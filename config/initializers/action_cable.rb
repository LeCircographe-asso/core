# frozen_string_literal: true

Rails.application.configure do
  config.action_cable.mount_path = "/cable"

  # Browser origins allowed to open a WebSocket to Action Cable (same-origin + dev).
  origins = [
    %r{\Ahttp://localhost(:\d+)?\z},
    %r{\Ahttp://127\.0\.0\.1(:\d+)?\z},
    "https://staging.lecircographe.fr",
    "https://lecircographe.fr",
    "https://www.lecircographe.fr"
  ]

  # Optional: extra comma-separated origins (e.g. preview deploy hostname).
  if ENV["ACTION_CABLE_ALLOWED_ORIGINS"].present?
    ENV["ACTION_CABLE_ALLOWED_ORIGINS"].split(",").map(&:strip).each do |origin|
      origins << origin if origin.present?
    end
  end

  config.action_cable.allowed_request_origins = origins
end
