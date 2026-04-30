#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'

# Set up RSpec
puts 'Setting up RSpec for your application...'

# Create backup of test folder
if Dir.exist?('test')
  puts 'Creating backup of test directory...'
  backup_dir = "test_backup_#{Time.zone.now.strftime('%Y%m%d%H%M%S')}"
  FileUtils.cp_r 'test', backup_dir
  puts "Test directory backed up to #{backup_dir}"

  # Remove test directory
  puts 'Removing test directory...'
  FileUtils.rm_rf 'test'
  puts 'Test directory removed.'
end

# Create all necessary directories for RSpec
dirs = [
  'spec/models',
  'spec/controllers',
  'spec/requests',
  'spec/services',
  'spec/factories',
  'spec/helpers',
  'spec/system',
  'spec/support'
]

dirs.each do |dir|
  unless Dir.exist?(dir)
    puts "Creating #{dir}..."
    FileUtils.mkdir_p dir
  end
end

puts "\nRSpec is now set up as your testing framework!"
puts "\nYou may need to run 'bundle install' to install any new gems."
puts "To run your tests, use 'bundle exec rspec'."
