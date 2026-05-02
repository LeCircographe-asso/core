# frozen_string_literal: true

RSpec.configure do |config|
  config.around(:each, :truncate) do |example|
    connection = ActiveRecord::Base.connection
    tables = connection.tables - %w[schema_migrations ar_internal_metadata sqlite_sequence]

    connection.disable_referential_integrity do
      tables.each { |table| connection.execute("DELETE FROM #{table}") }
    end

    example.run

    connection.disable_referential_integrity do
      tables.each { |table| connection.execute("DELETE FROM #{table}") }
    end
  end
end
