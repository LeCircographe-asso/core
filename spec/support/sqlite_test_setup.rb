# frozen_string_literal: true

require 'fileutils'

RSpec.configure do |config|
  config.before(:suite) do
    next unless ActiveRecord::Base.connection_db_config.adapter == 'sqlite3'

    %w[test test_cache test_queue test_cable].each do |env_name|
      ActiveRecord::Base.configurations.configs_for(env_name: env_name).each do |db_config|
        db_path = db_config.database
        next if db_path.blank? || db_path == ':memory:' || db_path.start_with?('file:')

        FileUtils.mkdir_p(File.dirname(db_path))
        FileUtils.touch(db_path)
      end
    end
  end
end
