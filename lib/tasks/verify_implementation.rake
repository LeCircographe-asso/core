namespace :verify do
  desc "Verify SQLite3 implementation is working properly"
  task sqlite: :environment do
    puts "=== SQLite3 Implementation Verification ==="

    # Check database connections
    puts "\n1. Checking database connections..."
    begin
      # Check main database
      main_connection = ActiveRecord::Base.connection
      main_adapter = main_connection.adapter_name
      puts "  - Main database: #{main_adapter == 'SQLite' ? '✓' : '✗'} (#{main_adapter})"

      # Check cache database
      ActiveRecord::Base.establish_connection(:"#{Rails.env}_cache")
      cache_connection = ActiveRecord::Base.connection
      cache_adapter = cache_connection.adapter_name
      puts "  - Cache database: #{cache_adapter == 'SQLite' ? '✓' : '✗'} (#{cache_adapter})"

      # Check queue database
      ActiveRecord::Base.establish_connection(:"#{Rails.env}_queue")
      queue_connection = ActiveRecord::Base.connection
      queue_adapter = queue_connection.adapter_name
      puts "  - Queue database: #{queue_adapter == 'SQLite' ? '✓' : '✗'} (#{queue_adapter})"

      # Check cable database
      ActiveRecord::Base.establish_connection(:"#{Rails.env}_cable")
      cable_connection = ActiveRecord::Base.connection
      cable_adapter = cable_connection.adapter_name
      puts "  - Cable database: #{cable_adapter == 'SQLite' ? '✓' : '✗'} (#{cable_adapter})"

      # Reconnect to main database
      ActiveRecord::Base.establish_connection(:"#{Rails.env}")
    rescue => e
      puts "  Error checking connections: #{e.message}"
    end

    # Verify database files exist
    puts "\n2. Verifying database files..."
    main_db = Rails.root.join("storage", "#{Rails.env}.sqlite3")
    cache_db = Rails.root.join("storage", "#{Rails.env}_cache.sqlite3")
    queue_db = Rails.root.join("storage", "#{Rails.env}_queue.sqlite3")
    cable_db = Rails.root.join("storage", "#{Rails.env}_cable.sqlite3")

    puts "  - Main database file: #{File.exist?(main_db) ? '✓' : '✗'} (#{main_db})"
    puts "  - Cache database file: #{File.exist?(cache_db) ? '✓' : '✗'} (#{cache_db})"
    puts "  - Queue database file: #{File.exist?(queue_db) ? '✓' : '✗'} (#{queue_db})"
    puts "  - Cable database file: #{File.exist?(cable_db) ? '✓' : '✗'} (#{cable_db})"

    # Test functionality
    puts "\n3. Testing functionality..."

    # Test cache
    begin
      Rails.cache.write("test_key", "test_value")
      cache_result = Rails.cache.read("test_key")
      puts "  - Cache functionality: #{cache_result == 'test_value' ? '✓' : '✗'}"
    rescue => e
      puts "  - Cache functionality: ✗ (#{e.message})"
    end

    # Test job queue (if available)
    if defined?(SolidQueue)
      begin
        job = SolidQueue::Job.create(class_name: "TestJob", arguments: [ "test" ], queue_name: "default")
        puts "  - Queue functionality: #{job.persisted? ? '✓' : '✗'}"
      rescue => e
        puts "  - Queue functionality: ✗ (#{e.message})"
      end
    else
      puts "  - Queue functionality: ⚠ (SolidQueue not available)"
    end

    puts "\nVerification complete!"
  end

  desc "Verify data integrity implementation"
  task integrity: :environment do
    puts "=== Data Integrity Implementation Verification ==="

    # Check soft deletion implementation
    puts "\n1. Checking soft deletion implementation..."
    user_model_file = Rails.root.join("app", "models", "user.rb")
    if File.exist?(user_model_file)
      user_model_content = File.read(user_model_file)
      if user_model_content.include?("SoftDeletable")
        puts "  - SoftDeletable concern used in User model: ✓"

        # Test soft deletion if possible
        if User.respond_to?(:with_deleted)
          test_user = User.create!(
            email_address: "soft_delete_test@example.com",
            first_name: "Test",
            last_name: "User",
            password: "password123",
            password_confirmation: "password123"
          )
          test_user.destroy
          found_user = User.with_deleted.find_by(email_address: "soft_delete_test@example.com")
          puts "  - Soft deletion works: #{found_user.present? && found_user.deleted? ? '✓' : '✗'}"

          # Clean up
          test_user.really_destroy! if test_user.respond_to?(:really_destroy!)
        else
          puts "  - Soft deletion functionality: ✗ (methods not available)"
        end
      else
        puts "  - SoftDeletable concern used in User model: ✗"
      end
    else
      puts "  - User model file not found: ✗"
    end

    # Check for deleted_at columns
    puts "\n2. Checking for deleted_at columns..."
    tables_to_check = [ "users", "payments", "orders", "user_memberships", "book_of_entries", "attendances" ]
    tables_to_check.each do |table|
      begin
        has_column = ActiveRecord::Base.connection.column_exists?(table, :deleted_at)
        puts "  - #{table}.deleted_at: #{has_column ? '✓' : '✗'}"
      rescue => e
        puts "  - #{table}.deleted_at: ? (#{e.message})"
      end
    end

    # Check for UUID in payments
    puts "\n3. Checking for UUID in payments..."
    begin
      has_uuid = ActiveRecord::Base.connection.column_exists?("payments", :uuid)
      puts "  - payments.uuid: #{has_uuid ? '✓' : '✗'}"
    rescue => e
      puts "  - payments.uuid: ? (#{e.message})"
    end

    # Check for audit logs
    puts "\n4. Checking for payment audit logs..."
    begin
      audit_logs_table = ActiveRecord::Base.connection.table_exists?("payment_audit_logs")
      puts "  - payment_audit_logs table: #{audit_logs_table ? '✓' : '✗'}"
    rescue => e
      puts "  - payment_audit_logs table: ? (#{e.message})"
    end

    # Check for accounting service
    puts "\n5. Checking for accounting service..."
    accounting_service_file = Rails.root.join("app", "services", "accounting_service.rb")
    puts "  - AccountingService file: #{File.exist?(accounting_service_file) ? '✓' : '✗'}"

    puts "\nVerification complete!"
  end

  desc "Verify roadmap implementation progress"
  task roadmap: :environment do
    puts "=== Roadmap Implementation Progress ==="

    # Check core features
    puts "\n1. Checking core features..."

    # Authentication
    auth_system = defined?(Devise) || File.exist?(Rails.root.join("app", "controllers", "sessions_controller.rb"))
    puts "  - Authentication system: #{auth_system ? '✓' : '⚠'}"

    # User management
    users_controller = File.exist?(Rails.root.join("app", "controllers", "users_controller.rb"))
    puts "  - User management: #{users_controller ? '✓' : '⚠'}"

    # Membership management
    memberships_controller = File.exist?(Rails.root.join("app", "controllers", "memberships_controller.rb"))
    puts "  - Membership management: #{memberships_controller ? '✓' : '⚠'}"

    # Payment processing
    payments_controller = File.exist?(Rails.root.join("app", "controllers", "payments_controller.rb"))
    puts "  - Payment processing: #{payments_controller ? '✓' : '⚠'}"

    # Attendance tracking
    attendances_controller = File.exist?(Rails.root.join("app", "controllers", "attendances_controller.rb"))
    puts "  - Attendance tracking: #{attendances_controller ? '✓' : '⚠'}"

    # Role management
    roles_controller = File.exist?(Rails.root.join("app", "controllers", "roles_controller.rb"))
    puts "  - Role management: #{roles_controller ? '✓' : '⚠'}"

    # Dashboard
    dashboard_controller = File.exist?(Rails.root.join("app", "controllers", "dashboard_controller.rb"))
    puts "  - Dashboard: #{dashboard_controller ? '✓' : '⚠'}"

    # Check UI components
    puts "\n2. Checking UI components..."

    # Hotwire
    has_hotwire = File.read(Rails.root.join("Gemfile")).include?("hotwire-rails") ||
                 File.read(Rails.root.join("Gemfile")).include?("turbo-rails")
    puts "  - Hotwire integration: #{has_hotwire ? '✓' : '⚠'}"

    # Tailwind
    has_tailwind = File.read(Rails.root.join("Gemfile")).include?("tailwindcss-rails")
    puts "  - Tailwind CSS: #{has_tailwind ? '✓' : '⚠'}"

    # Check controllers
    puts "\n3. Checking controller structure..."
    controllers_path = Rails.root.join("app", "controllers")
    admin_controllers = Dir.glob("#{controllers_path}/admin/*.rb").map { |f| File.basename(f, ".rb") }
    puts "  - Admin controllers: #{admin_controllers.join(', ')}"

    # Check models
    puts "\n4. Checking model structure..."
    models_path = Rails.root.join("app", "models")
    models = Dir.glob("#{models_path}/*.rb").map { |f| File.basename(f, ".rb") }
    puts "  - Models: #{models.join(', ')}"

    puts "\nRoadmap verification complete!"
  end
end
