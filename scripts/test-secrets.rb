#!/usr/bin/env ruby

# Script pour tester la configuration des secrets GitHub
# Usage: ruby scripts/test-secrets.rb

require 'net/http'
require 'json'

puts "🔐 Test de configuration des secrets GitHub"
puts "=" * 50

# Fonction pour vérifier si un secret existe
def check_secret_exists(org, repo, secret_name)
  # Note: Cette fonction nécessite un token GitHub avec les bonnes permissions
  # Pour l'instant, on simule la vérification
  puts "🔍 Vérification du secret: #{secret_name}"
  puts "   Organisation: #{org}"
  puts "   Repository: #{repo}"
  puts "   Status: À vérifier manuellement dans GitHub"
  puts ""
end

# Secrets requis
required_secrets = [
  'RAILS_MASTER_KEY',
  'KAMAL_REGISTRY_PASSWORD',
  'STAGING_SERVER_IP',
  'PRODUCTION_SERVER_IP'
]

puts "📋 Secrets requis pour le déploiement:"
required_secrets.each_with_index do |secret, index|
  puts "   #{index + 1}. #{secret}"
end
puts ""

puts "🎯 Instructions pour configurer les secrets:"
puts "1. Allez sur: https://github.com/organizations/LeCircographe-asso/settings/secrets/actions"
puts "2. Ajoutez chaque secret avec le nom exact ci-dessus"
puts "3. Pour KAMAL_REGISTRY_PASSWORD, utilisez le token Classic avec 'write:packages'"
puts ""

puts "🔧 Test de la configuration locale:"
puts "   Master key présent: #{File.exist?('config/master.key') ? '✅' : '❌'}"
puts "   Kamal config présent: #{File.exist?('config/deploy.yml') ? '✅' : '❌'}"
puts "   Staging config présent: #{File.exist?('config/deploy.staging.yml') ? '✅' : '❌'}"
puts ""

puts "📝 Prochaines étapes:"
puts "1. Créer le token Classic GitHub"
puts "2. Ajouter tous les secrets dans GitHub"
puts "3. Tester le déploiement staging"
puts "4. Valider le déploiement production"
