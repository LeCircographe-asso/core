# frozen_string_literal: true

return unless Rails.env.development?

module DevDbDeleteTrace
  module_function

  CRITICAL_TABLES = %w[users people sessions].freeze

  def subscribe_once!
    return if @subscribed

    ActiveSupport::Notifications.subscribe("sql.active_record") do |_name, _started, _finished, _unique_id, payload|
      sql = payload[:sql].to_s.squish
      table = extracted_table(sql)
      next unless table
      next unless CRITICAL_TABLES.include?(table)
      next if payload[:name] == "SCHEMA"

      DevIncidentLogger.log!(
        type: "critical_table_delete_detected",
        details: {
          table: table,
          sql: sql,
          where_clause: sql.include?(" WHERE "),
          source: app_source_from_backtrace,
          db: database_name(payload[:connection])
        }
      )
    end

    @subscribed = true
  end

  def extracted_table(sql)
    match = sql.match(/\ADELETE FROM "([^"]+)"/)
    match && match[1]
  end

  def app_source_from_backtrace
    locations = caller_locations(2, 40)
    app_path = Rails.root.to_s

    preferred = locations.find do |loc|
      path = loc.path
      path.start_with?(app_path) && (path.include?("/app/") || path.include?("/lib/") || path.include?("/db/") || path.include?("/bin/"))
    end

    preferred ||= locations.find { |loc| loc.path.start_with?(app_path) }
    preferred&.to_s
  end

  def database_name(connection)
    return nil unless connection.respond_to?(:pool)

    connection.pool&.db_config&.database
  end
end

Rails.application.config.after_initialize do
  DevDbDeleteTrace.subscribe_once!
end
