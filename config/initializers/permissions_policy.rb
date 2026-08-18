# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Define permissions for browser features (camera, microphone, geolocation, etc).
# See: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Permissions-Policy

Rails.application.configure do
  config.permissions_policy do |policy|
    # Disable camera — app never needs it
    policy.camera :none

    # Disable microphone — app never needs it
    policy.microphone :none

    # Disable geolocation — app never needs it
    policy.geolocation :none

    # Disable payment request API — app never initiates payments this way
    policy.payment :self

    # Disable USB access
    policy.usb :none

    # Allow accelerometer for responsive behavior (if needed by future mobile features)
    # policy.accelerometer :self

    # Allow gyroscope for responsive behavior (if needed by future mobile features)
    # policy.gyroscope :self
  end
end
