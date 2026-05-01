# frozen_string_literal: true

require "digest"

class DevIncidentLogger
  LOG_PATH = Rails.root.join("log", "dev_incidents.log")

  def self.log!(type:, details: {})
    normalized_details = details.to_h.deep_stringify_keys

    return unless Rails.env.development?

    incident = {
      at: Time.current.iso8601,
      type: type,
      pid: Process.pid,
      fingerprint: fingerprint_for(type: type, details: normalized_details),
      details: normalized_details
    }

    Rails.logger.warn("[dev.incident] #{incident.to_json}")
    File.open(LOG_PATH, "a") { |f| f.puts(incident.to_json) }
  rescue StandardError => e
    Rails.logger.warn("[dev.incident] failed_to_persist type=#{type} error=#{e.class}: #{e.message}")
  end

  def self.fingerprint_for(type:, details:)
    keys = %w[table email_address user_exists users_count where_clause db]
    compact_details = details.slice(*keys)
    payload = { type: type, details: compact_details }
    Digest::SHA256.hexdigest(payload.to_json).first(12)
  end
end
