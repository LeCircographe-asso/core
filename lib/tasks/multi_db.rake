namespace :db do
  desc "Run all migrations for all databases"
  task migrate_all: :environment do
    puts "Creating all SQLite databases..."

    # Create cache database
    cache_db_path = Rails.root.join("storage", "#{Rails.env}_cache.sqlite3")
    unless File.exist?(cache_db_path)
      puts "Creating cache database at #{cache_db_path}"
      SQLite3::Database.new(cache_db_path.to_s)
    end

    # Create queue database
    queue_db_path = Rails.root.join("storage", "#{Rails.env}_queue.sqlite3")
    unless File.exist?(queue_db_path)
      puts "Creating queue database at #{queue_db_path}"
      SQLite3::Database.new(queue_db_path.to_s)
    end

    # Create cable database
    cable_db_path = Rails.root.join("storage", "#{Rails.env}_cable.sqlite3")
    unless File.exist?(cable_db_path)
      puts "Creating cable database at #{cable_db_path}"
      SQLite3::Database.new(cable_db_path.to_s)
    end

    puts "Migrating main database..."
    Rake::Task["db:migrate"].invoke

    # Migrate SolidCache tables
    puts "Migrating cache database..."
    cache_migration = Rails.root.join("db", "cache_migrate", "20250420090000_create_solid_cache_tables.rb")
    load cache_migration
    ActiveRecord::Base.establish_connection(:"#{Rails.env}_cache") # connect to the cache database
    CreateSolidCacheTables.new.change

    # Migrate SolidQueue tables
    puts "Migrating queue database..."
    queue_migration = Rails.root.join("db", "queue_migrate", "20250420090000_create_solid_queue_tables.rb")
    load queue_migration
    ActiveRecord::Base.establish_connection(:"#{Rails.env}_queue") # connect to the queue database
    CreateSolidQueueTables.new.change

    # Migrate ActionCable tables
    puts "Migrating cable database..."
    cable_migration = Rails.root.join("db", "cable_migrate", "20250420090000_create_action_cable_tables.rb")
    load cable_migration
    ActiveRecord::Base.establish_connection(:"#{Rails.env}_cable") # connect to the cable database
    CreateActionCableTables.new.change

    # Reconnect to primary database
    ActiveRecord::Base.establish_connection(:"#{Rails.env}")

    puts "All migrations complete!"
  end
end
