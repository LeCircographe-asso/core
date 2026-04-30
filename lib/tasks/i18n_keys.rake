# frozen_string_literal: true

require "yaml"

def flatten_keys(hash, prefix = nil)
  hash.flat_map do |key, value|
    current = [ prefix, key ].compact.join(".")
    value.is_a?(Hash) ? flatten_keys(value, current) : [ current ]
  end
end

namespace :i18n do
  desc "Print locale key parity between fr and en"
  task check_keys: :environment do
    fr_data = YAML.load_file(Rails.root.join("config/locales/fr.yml"))["fr"] || {}
    en_data = YAML.load_file(Rails.root.join("config/locales/en.yml"))["en"] || {}

    fr_keys = flatten_keys(fr_data).sort
    en_keys = flatten_keys(en_data).sort

    missing_in_en = fr_keys - en_keys
    missing_in_fr = en_keys - fr_keys

    puts "Missing in en (#{missing_in_en.size})"
    missing_in_en.each { |k| puts "  - #{k}" }

    puts "\nMissing in fr (#{missing_in_fr.size})"
    missing_in_fr.each { |k| puts "  - #{k}" }

    if missing_in_en.empty? && missing_in_fr.empty?
      puts "\nLocale keys are in sync."
    else
      puts "\nLocale keys are not in sync."
      exit(1)
    end
  end
end
