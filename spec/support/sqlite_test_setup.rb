# frozen_string_literal: true

require "fileutils"

def configure_sqlite_busy_timeout!(connection)
  return unless connection.adapter_name.casecmp("sqlite").zero?

  connection.execute("PRAGMA busy_timeout = 5000")
end

RSpec.configure do |config|
  config.before(:suite) do
    connection = ActiveRecord::Base.connection
    next unless connection.adapter_name.casecmp("sqlite").zero?

    configure_sqlite_busy_timeout!(connection)

    %w[test test_cache test_queue test_cable].each do |env_name|
      ActiveRecord::Base.configurations.configs_for(env_name: env_name).each do |db_config|
        db_path = db_config.database
        next if db_path.blank? || db_path == ":memory:" || db_path.start_with?("file:")

        FileUtils.mkdir_p(File.dirname(db_path))
        FileUtils.touch(db_path)
      end
    end
  end

  config.before do
    configure_sqlite_busy_timeout!(ActiveRecord::Base.connection)
  end
end
