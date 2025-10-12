require "benchmark"
require "sqlite3"

namespace :benchmark do
  desc "Benchmark SQLite3 implementation performance"
  task performance: :environment do
    puts "=== SQLite3 Performance Benchmark ==="
    puts "Running on: #{Rails.env} environment"
    puts "Ruby version: #{RUBY_VERSION}"
    puts "Rails version: #{Rails::VERSION::STRING}"
    puts "SQLite version: #{SQLite3::SQLITE_VERSION}"
    puts "=================================="

    # Benchmark database operations
    puts "\n1. Database Operations"
    Benchmark.bm(30) do |x|
      # User creation
      x.report("Create 10 users:") do
        10.times do |i|
          User.create!(
            email_address: "benchmark_#{i}@example.com",
            first_name: "Benchmark",
            last_name: "User#{i}",
            password: "password123",
            password_confirmation: "password123"
          )
        end
      end

      # Read operations
      x.report("Find 10 users by ID:") do
        10.times do |i|
          User.find_by(email_address: "benchmark_#{i}@example.com")
        end
      end

      # Update operations
      x.report("Update 10 users:") do
        10.times do |i|
          user = User.find_by(email_address: "benchmark_#{i}@example.com")
          user.update(first_name: "Updated#{i}")
        end
      end

      # Complex queries
      x.report("Complex query with joins:") do
        5.times do
          User.includes(:payments, :memberships).where(deleted_at: nil).limit(5).to_a
        end
      end
    end

    # SolidCache benchmarks
    puts "\n2. Cache Operations"
    Benchmark.bm(30) do |x|
      x.report("Cache write 100 items:") do
        100.times do |i|
          Rails.cache.write("benchmark_key_#{i}", "benchmark_value_#{i}")
        end
      end

      x.report("Cache read 100 items:") do
        100.times do |i|
          Rails.cache.read("benchmark_key_#{i}")
        end
      end
    end

    # SolidQueue benchmarks
    puts "\n3. Background Job Operations"
    Benchmark.bm(30) do |x|
      x.report("Enqueue 10 jobs:") do
        10.times do |i|
          # This would normally use SampleJob.perform_later but for testing:
          begin
            ActiveRecord::Base.establish_connection(:"#{Rails.env}_queue")
            ActiveRecord::Base.connection.execute(
              "INSERT INTO solid_queue_jobs (queue_name, class_name, arguments, priority, created_at, updated_at)
               VALUES ('default', 'SampleJob', '[\"benchmark_#{i}\"]', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)"
            )
          rescue => e
            puts "  Error creating job: #{e.message}"
          ensure
            ActiveRecord::Base.establish_connection(:"#{Rails.env}")
          end
        end
      end
    end

    # Connection pooling test
    puts "\n4. Connection Pool Test"
    Benchmark.bm(30) do |x|
      x.report("5 concurrent connections:") do
        threads = []
        5.times do
          threads << Thread.new do
            User.first
          end
        end
        threads.each(&:join)
      end
    end

    # Clean up benchmark data
    puts "\nCleaning up benchmark data..."
    User.where("email_address LIKE 'benchmark_%@example.com'").destroy_all
    Rails.cache.delete_matched("benchmark_key_*")

    puts "\nBenchmark complete!"
  end

  desc "Check data integrity across the system"
  task integrity: :environment do
    puts "=== Data Integrity Check ==="

    # Check for orphaned records
    puts "\n1. Checking for orphaned records..."
    orphaned_payments = Payment.left_joins(:user).where(users: { id: nil }).count
    puts "  - Orphaned payments: #{orphaned_payments}"

    # Check soft deleted users with active records
    puts "\n2. Checking soft-deleted users with active records..."
    if User.respond_to?(:with_deleted)
      deleted_users_with_active = User.only_deleted.joins(:payments).where(payments: { deleted_at: nil }).count
      puts "  - Soft-deleted users with active payments: #{deleted_users_with_active}"
    else
      puts "  - Soft deletion not implemented yet"
    end

    # Check for payment reconciliation
    puts "\n3. Payment reconciliation check..."
    total_payments = Payment.sum(:payment_amount)
    total_by_user = User.joins(:payments).group(:id).sum("payments.payment_amount")
    puts "  - Total payments: #{total_payments}"
    puts "  - Total payments by user sum: #{total_by_user.values.sum}"
    puts "  - Reconciliation #{total_payments == total_by_user.values.sum ? 'SUCCESS' : 'FAILED'}"

    puts "\nData integrity check complete!"
  end
end
