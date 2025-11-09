#!/usr/bin/env ruby
# Script pour migrer automatiquement les services vers BaseService
# Usage: ruby scripts/migrate_to_base_service.rb

require 'fileutils'

SERVICES_DIR = 'app/services'
EXCLUDED_FILES = [ 'base_service.rb', '.disabled' ]

def find_services_to_migrate
  Dir.glob("#{SERVICES_DIR}/**/*.rb").select do |file|
    next if EXCLUDED_FILES.any? { |excluded| file.include?(excluded) }

    content = File.read(file)
    content.include?('require "ostruct"') && !content.include?('< BaseService')
  end
end

def migrate_service(file_path)
  content = File.read(file_path)
  original_content = content.dup

  # 1. Remplacer la déclaration de classe
  content.gsub!(/^require "ostruct"\s*$/, '')
  content.gsub!(/^module (\w+)\s*$/, 'module \1')
  content.gsub!(/class (\w+)\s*$/, 'class \1 < BaseService')
  content.gsub!(/^\s*include ActiveModel::Model\s*$/, '')
  content.gsub!(/^\s*include ActiveModel::Attributes\s*$/, '')

  # 2. Supprimer les méthodes success/failure
  content.gsub!(/^\s*private\s*$\n\s*def success\(.*?\)\s*$\n\s*OpenStruct\.new\(.*?\)\s*$\n\s*end\s*$\n\s*def failure\(.*?\)\s*$\n\s*OpenStruct\.new\(.*?\)\s*$\n\s*end\s*$/m, "    private\n\n    # success et failure hérités de BaseService\n")

  # 3. Adapter les appels success() - pattern simple
  # Note: Les appels complexes nécessitent une vérification manuelle

  if content != original_content
    File.write(file_path, content)
    puts "✅ Migré: #{file_path}"
    true
  else
    puts "⚠️  Aucun changement: #{file_path}"
    false
  end
end

# Script principal
services = find_services_to_migrate
puts "=== Migration BaseService ==="
puts "Services à migrer: #{services.count}"
puts ""

migrated = 0
services.each do |file|
  if migrate_service(file)
    migrated += 1
  end
end

puts ""
puts "✅ Migration terminée: #{migrated}/#{services.count} services migrés"
puts "⚠️  Note: Vérifiez manuellement les appels success() avec arguments complexes"
