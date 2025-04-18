namespace :ci do
  desc "Run all tests and generate reports for CI"
  task :tests do
    # Run tests with JUnit formatter for CI reporting
    puts "\n=== Running RSpec tests ==="
    system("bundle exec rspec --format progress --format RspecJunitFormatter --out rspec.xml")

    exit $?.exitstatus unless $?.success?
  end

  desc "Run RuboCop for CI"
  task :rubocop do
    puts "\n=== Running RuboCop ==="
    system("bundle exec rubocop --format json --out rubocop.json")
    # Don't fail the build for linting issues
  end

  desc "Run Brakeman for CI"
  task :brakeman do
    puts "\n=== Running Brakeman ==="
    system("bundle exec brakeman -f json -o brakeman.json")
    # Don't fail the build for security warnings at this stage
  end

  desc "Run all CI tasks"
  task all: [ :tests, :rubocop, :brakeman ] do
    puts "\n=== All CI tasks completed ==="
  end
end

# Set as default task for CI
task ci: "ci:all"
