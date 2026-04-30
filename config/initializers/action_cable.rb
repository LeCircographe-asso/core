# frozen_string_literal: true

Rails.application.configure do
  config.action_cable.mount_path = '/cable'
  config.action_cable.allowed_request_origins = [%r{http://localhost.*}]
end
