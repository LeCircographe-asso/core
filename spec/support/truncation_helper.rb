RSpec.configure do |config|
  config.before(:each) do
    ActiveRecord::Base.connection.disable_referential_integrity do
      tables = ActiveRecord::Base.connection.tables - %w[schema_migrations ar_internal_metadata sqlite_sequence]
      tables.each { |table| ActiveRecord::Base.connection.execute("DELETE FROM #{table}") }
    end
  end
end
